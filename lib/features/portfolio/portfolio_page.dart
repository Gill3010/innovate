import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import 'data/projects_service.dart';
import '../auth/data/auth_store.dart';
import 'widgets/project_form.dart';
import 'widgets/portfolio_filters.dart';
import 'widgets/project_card.dart';
import 'widgets/share_dialogs.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _category = 'all';
  bool _explore = false;
  late final ProjectsService _service;
  Future<List<ProjectItem>>? _future;
  String? _lastToken;

  @override
  void initState() {
    super.initState();
    _service = ProjectsService(ApiClient());
    _future = _load();
    _lastToken = AuthStore.instance.tokenValue;
  }

  Future<List<ProjectItem>> _load() async {
    if (_explore) {
      final res = await _service.listPublic(
        page: 1,
        perPage: 50,
        category: _category == 'all' ? null : _category,
      );
      return res.items;
    } else {
      // Si no hay sesión iniciada, no traigas nada para "Mis proyectos"
      final token = AuthStore.instance.tokenValue;
      if (token == null || token.isEmpty) return <ProjectItem>[];
      return _service.list(category: _category == 'all' ? null : _category);
    }
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
                final List a = (p.images.isNotEmpty)
                    ? (jsonDecode(p.images) as List)
                    : const [];
                return a.map((e) => e.toString()).toList();
              } catch (_) {
                return <String>[];
              }
            }(),
            links: () {
              try {
                final List a = (p.links.isNotEmpty)
                    ? (jsonDecode(p.links) as List)
                    : const [];
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
      // shareUrl is already absolute from service
      await ShareDialogs.showShareProjectDialog(context, shareUrl);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al compartir: $e')));
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
        final token = snap.data;
        if (token != _lastToken) {
          _lastToken = token;
          // Refresca automáticamente al cambiar de sesión/usuario
          _future = _load();
        }
        final logged = token != null;
        return Stack(
          children: [
            Column(
              children: [
                PortfolioFilters(
                  searchController: _searchCtrl,
                  category: _category,
                  explore: _explore,
                  isLoggedIn: logged,
                  onCategoryChanged: (v) {
                    _category = v;
                    _refresh();
                  },
                  onExploreChanged: (v) {
                    _explore = v;
                    _refresh();
                  },
                  onRefresh: _refresh,
                  onCreate: _create,
                  onSearchChanged: () => setState(() {}),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      _refresh();
                      await Future.delayed(const Duration(milliseconds: 200));
                    },
                    child: FutureBuilder<List<ProjectItem>>(
                      future: _future,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!_explore && !logged) {
                          return const Center(
                            child: Text('Inicia sesión para ver tus proyectos'),
                          );
                        }
                        if (snap.hasError) {
                          return Center(
                            child: Text('Error al cargar: ${snap.error}'),
                          );
                        }
                        final items = (snap.data ?? const <ProjectItem>[])
                            .where((p) {
                              final q = _searchCtrl.text.toLowerCase();
                              final s =
                                  '${p.title} ${p.technologies} ${p.category}'
                                      .toLowerCase();
                              return q.isEmpty || s.contains(q);
                            })
                            .toList();

                        if (items.isEmpty) {
                          return const Center(child: Text('Sin resultados'));
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: 0.9,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final p = items[index];
                            return ProjectCard(
                              project: p,
                              isLoggedIn: logged,
                              isExploreMode: _explore,
                              onShare: () => _share(p),
                              onEdit: () => _edit(p),
                              onDelete: () => _delete(p),
                            );
                          },
                        );
                      },
                    ),
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
