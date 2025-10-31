import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import 'data/projects_service.dart';

class PublicProfilePage extends StatefulWidget {
  const PublicProfilePage({super.key, required this.token});
  final String token;

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  late final ProjectsService _service;
  Future<(Map<String, dynamic>, List<ProjectItem>)>? _future;

  @override
  void initState() {
    super.initState();
    _service = ProjectsService(ApiClient());
    _future = _load();
  }

  Future<(Map<String, dynamic>, List<ProjectItem>)> _load() async {
    try {
      // El backend expone /api/users/profile/<token> y /api/projects/portfolio/<token>
      final profile = await _service.getPublicProfile(widget.token);
      final projects = await _service.listPortfolioByToken(widget.token);
      return (profile, projects);
    } catch (e) {
      // Log del error para debugging
      print('Error cargando perfil público: $e');
      print('Token usado: ${widget.token}');
      rethrow;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil público')),
      body: FutureBuilder<(Map<String, dynamic>, List<ProjectItem>)>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final (profile, items) = snap.data!;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile['name'] ?? '',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text('Proyectos: ${items.length}'),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final p = items[index];
                    final apiClient = ApiClient();
                    final baseUrl = apiClient.baseUrl;
                    String? thumbUrl;
                    List<String> linkList = const [];
                    try {
                      final List imgs = (p.images.isNotEmpty)
                          ? (jsonDecode(p.images) as List)
                          : const [];
                      if (imgs.isNotEmpty) {
                        final imgPath = imgs.first?.toString() ?? '';
                        if (imgPath.isNotEmpty) {
                          // Si la URL ya es absoluta (Firebase Storage), usar tal cual
                          if (imgPath.startsWith('http://') ||
                              imgPath.startsWith('https://')) {
                            thumbUrl = imgPath;
                          } else {
                            // URL relativa, convertir a absoluta
                            thumbUrl = '$baseUrl$imgPath';
                          }
                        }
                      }
                      final List lnks = (p.links.isNotEmpty)
                          ? (jsonDecode(p.links) as List)
                          : const [];
                      linkList = lnks
                          .map((e) => e.toString())
                          .toList(growable: false);
                    } catch (_) {}
                    final isLightMode =
                        Theme.of(context).brightness == Brightness.light;
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      color: isLightMode ? Colors.transparent : null,
                      shape: isLightMode
                          ? RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                color: Color(0xFFE5E7EB),
                                width: 1,
                              ),
                            )
                          : null,
                      child: Container(
                        decoration: isLightMode
                            ? BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    const Color(0xFFF0F9FF).withOpacity(0.5),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              )
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (thumbUrl != null && thumbUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    height: 100,
                                    width: double.infinity,
                                    child: Image.network(
                                      thumbUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              if (thumbUrl != null) const SizedBox(height: 6),
                              Text(
                                p.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              if (linkList.isNotEmpty)
                                InkWell(
                                  onTap: () async {
                                    final uri = Uri.tryParse(linkList.first);
                                    if (uri != null) {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.link, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Abrir',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }, childCount: items.length),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
