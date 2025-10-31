import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import 'data/projects_service.dart';

class ProjectDetailPage extends StatefulWidget {
  const ProjectDetailPage({super.key, required this.projectId});
  final String projectId;

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  late final ProjectsService _service;
  Future<ProjectItem>? _future;

  @override
  void initState() {
    super.initState();
    _service = ProjectsService(ApiClient());
    _future = _service.getById(widget.projectId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proyecto')),
      body: FutureBuilder<ProjectItem>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final p = snap.data!;
          final techChips = p.technologies
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          final links = _parseJsonArray(p.links);
          final imagesRaw = _parseJsonArray(p.images);
          final apiClient = ApiClient();
          final baseUrl = apiClient.baseUrl;
          // Convertir URLs relativas a absolutas, pero mantener URLs absolutas tal cual
          final images = imagesRaw.map((img) {
            if (img.startsWith('http://') || img.startsWith('https://')) {
              // URL ya es absoluta (probablemente de Firebase Storage), usar tal cual
              return img;
            }
            // URL relativa, convertir a absoluta
            return '$baseUrl$img';
          }).toList();
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(p.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final t in techChips) Chip(label: Text(t))],
                ),
                const SizedBox(height: 16),
                Text(p.description),
                const SizedBox(height: 16),
                if (images.isNotEmpty)
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            images[i],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final l in links)
                      FilledButton.tonal(
                        onPressed: () async {
                          final uri = Uri.tryParse(l);
                          if (uri != null) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: Text(l),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<String> _parseJsonArray(String raw) {
    if (raw.isEmpty) return [];
    try {
      final List a = jsonDecode(raw) as List;
      // Filtrar solo URLs válidas (que empiecen con http:// o https://)
      return a
          .map((e) => '$e')
          .where(
            (url) =>
                url.isNotEmpty &&
                (url.startsWith('http://') || url.startsWith('https://')),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }
}
