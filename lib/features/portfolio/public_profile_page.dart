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
    // El backend expone /api/users/profile/<token> y /api/projects/portfolio/<token>
    final profile = await _service.getPublicProfile(widget.token);
    final projects = await _service.listPortfolioByToken(widget.token);
    return (profile, projects);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1100 ? 4 : width > 800 ? 3 : width > 600 ? 2 : 1;
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
                      Text(profile['name'] ?? '', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text('Proyectos: ${items.length}')
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 4 / 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final p = items[index];
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
                                    child: Image.network(thumbUrl!, fit: BoxFit.cover),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium),
                              const Spacer(),
                              if (linkList.isNotEmpty)
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      final uri = Uri.tryParse(linkList.first);
                                      if (uri != null) {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      }
                                    },
                                    icon: const Icon(Icons.link),
                                    label: const Text('Abrir'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

