import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import 'data/projects_service.dart';
import '../auth/data/auth_store.dart';
import 'widgets/project_form.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _category = 'all';
  late final ProjectsService _service;
  Future<List<ProjectItem>>? _future;

  @override
  void initState() {
    super.initState();
    _service = ProjectsService(ApiClient());
    _future = _load();
  }

  Future<List<ProjectItem>> _load() {
    return _service.list(category: _category == 'all' ? null : _category);
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _create() async {
    final data = await showModalBottomSheet<ProjectFormData>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const ProjectForm(),
      ),
    );
    if (data == null) return;
    try {
      await _service.create(
        title: data.title,
        description: data.description,
        technologies: data.technologies,
        category: data.category,
        featured: data.featured,
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al crear: $e')));
    }
  }

  Future<void> _edit(ProjectItem p) async {
    final data = await showModalBottomSheet<ProjectFormData>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ProjectForm(
          initial: ProjectFormData(
            title: p.title,
            description: p.description,
            technologies: p.technologies,
            category: p.category,
            featured: p.featured,
          ),
        ),
      ),
    );
    if (data == null) return;
    try {
      await _service.update(
        p.id,
        title: data.title,
        description: data.description,
        technologies: data.technologies,
        category: data.category,
        featured: data.featured,
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  Future<void> _delete(ProjectItem p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar proyecto'),
        content: Text('¿Eliminar "${p.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.delete(p.id);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1100
        ? 4
        : width > 800
        ? 3
        : width > 600
        ? 2
        : 1;

    final logged = AuthStore.instance.isLoggedIn;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Buscar proyectos...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _category,
                    onChanged: (v) {
                      _category = v ?? 'all';
                      _refresh();
                    },
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Todos')),
                      DropdownMenuItem(value: 'web', child: Text('Web')),
                      DropdownMenuItem(value: 'mobile', child: Text('Móvil')),
                    ],
                  ),
                  IconButton(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ProjectItem>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text('Error al cargar: ${snap.error}'),
                    );
                  }
                  final items = (snap.data ?? const <ProjectItem>[]).where((p) {
                    final q = _searchCtrl.text.toLowerCase();
                    final s = '${p.title} ${p.technologies} ${p.category}'
                        .toLowerCase();
                    return q.isEmpty || s.contains(q);
                  }).toList();

                  if (items.isEmpty) {
                    return const Center(child: Text('Sin resultados'));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 4 / 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final p = items[index];
                      return Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                  if (logged) ...[
                                    IconButton(
                                      tooltip: 'Editar',
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _edit(p),
                                    ),
                                    IconButton(
                                      tooltip: 'Eliminar',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _delete(p),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Categoría: ${p.category}').applyTextStyle(
                                Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tecnologías: ${p.technologies}',
                              ).applyTextStyle(
                                Theme.of(context).textTheme.bodyMedium,
                              ),
                              const Spacer(),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: const Text('Ver detalle'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        if (logged)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo'),
            ),
          ),
      ],
    );
  }
}

extension on Widget {
  Widget applyTextStyle(TextStyle? style) =>
      DefaultTextStyle.merge(style: style, child: this);
}
