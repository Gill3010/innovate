import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import 'data/projects_service.dart';

class ProjectDetailPage extends StatefulWidget {
  const ProjectDetailPage({super.key, required this.projectId});
  final int projectId;

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
          final images = _parseJsonArray(p.images);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(p.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final t in techChips)
                    Chip(label: Text(t)),
                ]),
                const SizedBox(height: 16),
                Text(p.description),
                const SizedBox(height: 16),
                if (images.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Center(child: Text('Imagen ${i + 1}')),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Wrap(spacing: 8, children: [
                  for (final l in links)
                    FilledButton.tonal(
                      onPressed: () async {
                        // ignore: deprecated_member_use
                        // You can wire url_launcher here later
                      },
                      child: Text(l),
                    ),
                ])
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
      return a.map((e) => '$e').toList();
    } catch (_) {
      return [];
    }
  }
}

