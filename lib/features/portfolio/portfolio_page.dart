import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/api_client.dart';
import 'data/projects_service.dart';
import '../auth/data/auth_store.dart';
import 'widgets/project_form.dart';
import 'project_detail_page.dart';

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
    // Escucha cambios de sesión para mostrar/ocultar botones de dueño
    AuthStore.instance.token.listen((_) {
      if (mounted) setState(() {});
    });
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
        images: data.imagesJson(),
        links: data.linksJson(),
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
            images: () {
              try {
                final List a = (p.images.isNotEmpty) ? (jsonDecode(p.images) as List) : const [];
                return a.map((e) => e.toString()).toList();
              } catch (_) {
                return <String>[];
              }
            }(),
            links: () {
              try {
                final List a = (p.links.isNotEmpty) ? (jsonDecode(p.links) as List) : const [];
                return a.map((e) => e.toString()).toList();
              } catch (_) {
                return <String>[];
              }
            }(),
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
        images: data.imagesJson(),
        links: data.linksJson(),
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

  Future<void> _share(ProjectItem p) async {
    try {
      final shareUrl = await _service.share(p.id);
      if (!mounted) return;
      final fullUrl = '${ApiClient.defaultBaseUrl}$shareUrl';
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Compartir proyecto'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText(fullUrl),
                const SizedBox(height: 12),
                SizedBox(
                  width: 180,
                  height: 180,
                  child: QrImageView(
                    data: fullUrl,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: fullUrl));
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enlace copiado')),
                  );
                }
              },
              child: const Text('Copiar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al compartir: $e')));
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

    return StreamBuilder<String?>(
      stream: AuthStore.instance.token,
      builder: (context, snap) {
        final logged = snap.data != null;
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
                      if (logged)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilledButton.icon(
                            onPressed: _create,
                            icon: const Icon(Icons.add),
                            label: const Text('Nuevo'),
                          ),
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
                      // Try to parse first image from JSON string
                      String? thumbUrl;
                      List<String> linkList = const [];
                      try {
                        final List imgs = (p.images.isNotEmpty) ? (jsonDecode(p.images) as List) : const [];
                        if (imgs.isNotEmpty) thumbUrl = imgs.first?.toString();
                        final List lnks = (p.links.isNotEmpty) ? (jsonDecode(p.links) as List) : const [];
                        linkList = lnks.map((e) => e.toString()).toList(growable: false);
                      } catch (_) {}
                      return Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (thumbUrl != null && thumbUrl!.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    height: 120,
                                    width: double.infinity,
                                    child: Image.network(
                                      thumbUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        child: const Center(child: Icon(Icons.broken_image)),
                                      ),
                                    ),
                                  ),
                                ),
                              if (thumbUrl != null) const SizedBox(height: 8),
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
                                  if (linkList.isNotEmpty)
                                    PopupMenuButton<String>(
                                      tooltip: 'Abrir enlace',
                                      icon: const Icon(Icons.link),
                                      itemBuilder: (context) => [
                                        for (final l in linkList)
                                          PopupMenuItem<String>(
                                            value: l,
                                            child: SizedBox(
                                              width: 240,
                                              child: Text(l, overflow: TextOverflow.ellipsis),
                                            ),
                                          ),
                                      ],
                                      onSelected: (l) async {
                                        final uri = Uri.tryParse(l);
                                        if (uri != null) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                    ),
                                  if (logged) ...[
                                    IconButton(
                                      tooltip: 'Compartir',
                                      icon: const Icon(Icons.share),
                                      onPressed: () => _share(p),
                                    ),
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
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProjectDetailPage(projectId: p.id),
                                      ),
                                    );
                                  },
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
                right: 16,
                bottom: 16,
                child: SafeArea(
                  child: FloatingActionButton.extended(
                    heroTag: 'newProjectFab',
                    onPressed: _create,
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo'),
                  ),
                ),
        ),
      ],
    );
      },
    );
  }
}

extension on Widget {
  Widget applyTextStyle(TextStyle? style) =>
      DefaultTextStyle.merge(style: style, child: this);
}
