import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../data/auth_service.dart';
import '../data/auth_store.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLogin = true;
  bool _busy = false;
  late final AuthService _auth;

  @override
  void initState() {
    super.initState();
    _auth = AuthService(ApiClient());
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) return;
    setState(() => _busy = true);
    try {
      if (_isLogin) {
        await _auth.login(email: email, password: pass);
      } else {
        await _auth.register(email: email, password: pass);
        await _auth.login(email: email, password: pass);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logged = AuthStore.instance.isLoggedIn;
    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (logged)
              Row(
                children: [
                  const Icon(Icons.verified_user),
                  const SizedBox(width: 8),
                  const Text('Sesión iniciada'),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      await AuthStore.instance.clear();
                      if (!mounted) return;
                      Navigator.pop(context, true);
                    },
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              )
            else ...[
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isLogin ? 'Iniciar sesión' : 'Registrarme'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin ? 'Crear cuenta' : 'Ya tengo cuenta'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
