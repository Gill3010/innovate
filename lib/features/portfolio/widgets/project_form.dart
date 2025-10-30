import 'package:flutter/material.dart';

class ProjectFormData {
  ProjectFormData({
    this.title = '',
    this.description = '',
    this.technologies = '',
    this.category = 'general',
    this.featured = false,
  });

  String title;
  String description;
  String technologies;
  String category;
  bool featured;
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

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? ProjectFormData();
    _title = TextEditingController(text: i.title);
    _desc = TextEditingController(text: i.description);
    _tech = TextEditingController(text: i.technologies);
    _category = i.category;
    _featured = i.featured;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 16),
          Row(
            children: [
              const Spacer(),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final data = ProjectFormData(
                    title: _title.text.trim(),
                    description: _desc.text.trim(),
                    technologies: _tech.text.trim(),
                    category: _category,
                    featured: _featured,
                  );
                  Navigator.pop(context, data);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
