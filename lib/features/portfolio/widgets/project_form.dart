import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../data/image_upload_service.dart';
import 'image_picker_dialog.dart';

class ProjectFormData {
  ProjectFormData({
    this.title = '',
    this.description = '',
    this.technologies = '',
    this.category = 'general',
    this.featured = false,
    List<String>? images,
    List<String>? links,
  })  : images = images ?? <String>[],
        links = links ?? <String>[];

  String title;
  String description;
  String technologies;
  String category;
  bool featured;
  List<String> images;
  List<String> links;

  String imagesJson() => jsonEncode(images);
  String linksJson() => jsonEncode(links);
}

class ProjectForm extends StatefulWidget {
  const ProjectForm({super.key, this.initial});
  final ProjectFormData? initial;

  @override
  State<ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<ProjectForm> {
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late final TextEditingController _tech;
  String _category = 'general';
  bool _featured = false;
  late final ImageUploadService _uploadService;
  final List<String> _images = [];
  final List<String> _links = [];

  @override
  void initState() {
    super.initState();
    _uploadService = ImageUploadService(ApiClient());
    final i = widget.initial ?? ProjectFormData();
    _title = TextEditingController(text: i.title);
    _desc = TextEditingController(text: i.description);
    _tech = TextEditingController(text: i.technologies);
    _category = i.category;
    _featured = i.featured;
    _images.addAll(i.images);
    _links.addAll(i.links);
  }

  Future<void> _pickAndUploadImages() async {
    final urls = await _uploadService.pickAndUploadFromFiles();
    _images.addAll(urls);
    if (mounted) setState(() {});
  }

  Future<void> _pickFromGalleryOrCamera() async {
    final action = await ImagePickerDialog.showPickerOptions(context);
    if (action == null) return;

    if (action == 'gallery') {
      final urls = await _uploadService.pickAndUploadFromGallery();
      _images.addAll(urls);
    } else {
      final url = await _uploadService.pickAndUploadFromCamera();
      if (url != null) _images.add(url);
    }
    if (mounted) setState(() {});
  }

  void _addLink() async {
    final added = await ImagePickerDialog.showAddLinkDialog(context);
    if (added != null && added.isNotEmpty) {
      _links.add(added);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Título')),
          const SizedBox(height: 12),
          TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Descripción'), maxLines: 3),
          const SizedBox(height: 12),
          TextField(controller: _tech, decoration: const InputDecoration(labelText: 'Tecnologías (comma-separated)')),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Categoría:'),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _category,
                onChanged: (v) => setState(() => _category = v ?? 'general'),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('General')),
                  DropdownMenuItem(value: 'web', child: Text('Web')),
                  DropdownMenuItem(value: 'mobile', child: Text('Móvil')),
                ],
              ),
              const Spacer(),
              Checkbox(value: _featured, onChanged: (v) => setState(() => _featured = v ?? false)),
              const Text('Destacado'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(onPressed: _pickAndUploadImages, child: const Text('Agregar imágenes')),
              FilledButton.tonal(onPressed: _pickFromGalleryOrCamera, child: const Text('Galería/Cámara')),
              TextButton(onPressed: _addLink, child: const Text('Agregar link')),
            ],
          ),
          const SizedBox(height: 8),
          if (_images.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(_images[i], width: 140, height: 100, fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _images.removeAt(i)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_links.isNotEmpty)
            Wrap(spacing: 8, children: [
              for (final l in _links)
                Chip(
                  label: Text(l, overflow: TextOverflow.ellipsis),
                  onDeleted: () => setState(() => _links.remove(l)),
                ),
            ]),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  final data = ProjectFormData(
                    title: _title.text.trim(),
                    description: _desc.text.trim(),
                    technologies: _tech.text.trim(),
                    category: _category,
                    featured: _featured,
                    images: List.of(_images),
                    links: List.of(_links),
                  );
                  Navigator.pop(context, data);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    ),
    );
  }
}
