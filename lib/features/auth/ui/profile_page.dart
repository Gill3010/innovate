import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../data/user_service.dart';
import '../data/auth_store.dart';
import '../../portfolio/data/image_upload_service.dart';
import 'widgets/profile_avatar_widget.dart';
import 'widgets/profile_basic_fields.dart';
import 'widgets/profile_social_fields.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  
  late final UserService _service;
  late final ImageUploadService _imageService;
  UserProfile? _profile;
  bool _loading = false;
  bool _saving = false;
  String? _tempAvatarUrl;

  @override
  void initState() {
    super.initState();
    _service = UserService(ApiClient());
    _imageService = ImageUploadService(ApiClient());
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final profile = await _service.getProfile();
      _nameCtrl.text = profile.name;
      _bioCtrl.text = profile.bio;
      _titleCtrl.text = profile.title;
      _locationCtrl.text = profile.location;
      _phoneCtrl.text = profile.phone;
      _linkedinCtrl.text = profile.linkedinUrl;
      _githubCtrl.text = profile.githubUrl;
      _websiteCtrl.text = profile.websiteUrl;
      setState(() => _profile = profile);
    } catch (e) {
      if (!mounted) return;
      final errorStr = e.toString();
      // Si es un error de autenticación o autorización, cerrar sesión automáticamente
      if (errorStr.contains('401') || errorStr.contains('404') || errorStr.contains('422')) {
        await AuthStore.instance.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tu sesión ha expirado. Por favor inicia sesión de nuevo.')),
          );
          Navigator.pop(context, true);
        }
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar perfil: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final urls = await _imageService.pickAndUploadFromGallery();
    if (urls.isNotEmpty) {
      setState(() => _tempAvatarUrl = urls.first);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = UserProfile(
        id: _profile!.id,
        email: _profile!.email,
        name: _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        avatarUrl: _tempAvatarUrl ?? _profile!.avatarUrl,
        phone: _phoneCtrl.text.trim(),
        linkedinUrl: _linkedinCtrl.text.trim(),
        githubUrl: _githubCtrl.text.trim(),
        websiteUrl: _websiteCtrl.text.trim(),
        portfolioShareToken: _profile!.portfolioShareToken,
        createdAt: _profile!.createdAt,
      );
      await _service.updateProfile(updated);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    _linkedinCtrl.dispose();
    _githubCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi perfil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi perfil')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No se pudo cargar el perfil'),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ProfileAvatarWidget(
            avatarUrl: _profile!.avatarUrl,
            tempAvatarUrl: _tempAvatarUrl,
            onPickAvatar: _pickAvatar,
          ),
          const SizedBox(height: 24),
          ProfileBasicFields(
            nameCtrl: _nameCtrl,
            titleCtrl: _titleCtrl,
            locationCtrl: _locationCtrl,
            bioCtrl: _bioCtrl,
            phoneCtrl: _phoneCtrl,
          ),
          ProfileSocialFields(
            linkedinCtrl: _linkedinCtrl,
            githubCtrl: _githubCtrl,
            websiteCtrl: _websiteCtrl,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save),
            label: const Text('Guardar cambios'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _saving ? null : _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AuthStore.instance.clear();
    if (!mounted) return;
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión cerrada')),
    );
  }
}
