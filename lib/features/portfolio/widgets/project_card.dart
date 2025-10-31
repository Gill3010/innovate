import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/projects_service.dart';
import '../project_detail_page.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.isLoggedIn,
    required this.isExploreMode,
    required this.onShare,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectItem project;
  final bool isLoggedIn;
  final bool isExploreMode;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    String? thumbUrl;
    List<String> linkList = const [];

    try {
      final List imgs = (project.images.isNotEmpty)
          ? (jsonDecode(project.images) as List)
          : const [];
      if (imgs.isNotEmpty) thumbUrl = imgs.first?.toString();

      final List lnks = (project.links.isNotEmpty)
          ? (jsonDecode(project.links) as List)
          : const [];
      linkList = lnks.map((e) => e.toString()).toList(growable: false);
    } catch (_) {}

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (thumbUrl != null && thumbUrl.isNotEmpty)
              _ProjectThumbnail(thumbUrl: thumbUrl),
            if (thumbUrl != null) const SizedBox(height: 6),
            _ProjectHeader(
              project: project,
              linkList: linkList,
              isLoggedIn: isLoggedIn,
              isExploreMode: isExploreMode,
              onShare: onShare,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
            const SizedBox(height: 4),
            _ProjectInfo(project: project),
            const SizedBox(height: 4),
            _ProjectDetailButton(projectId: project.id),
          ],
        ),
      ),
    );
  }
}

class _ProjectThumbnail extends StatelessWidget {
  const _ProjectThumbnail({required this.thumbUrl});

  final String thumbUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: Image.network(
          thumbUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(child: Icon(Icons.broken_image)),
          ),
        ),
      ),
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({
    required this.project,
    required this.linkList,
    required this.isLoggedIn,
    required this.isExploreMode,
    required this.onShare,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectItem project;
  final List<String> linkList;
  final bool isLoggedIn;
  final bool isExploreMode;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            project.title,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (linkList.isNotEmpty) _ProjectLinksMenu(linkList: linkList),
        if (isLoggedIn && !isExploreMode) ...[
          IconButton(
            tooltip: 'Compartir',
            icon: const Icon(Icons.share),
            onPressed: onShare,
          ),
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ],
    );
  }
}

class _ProjectLinksMenu extends StatelessWidget {
  const _ProjectLinksMenu({required this.linkList});

  final List<String> linkList;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
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
    );
  }
}

class _ProjectInfo extends StatelessWidget {
  const _ProjectInfo({required this.project});

  final ProjectItem project;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Categoría: ${project.category}',
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          'Tecnologías: ${project.technologies}',
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ProjectDetailButton extends StatelessWidget {
  const _ProjectDetailButton({required this.projectId});

  final int projectId;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProjectDetailPage(projectId: projectId),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Text(
          'Ver detalle',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
