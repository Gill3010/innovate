import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/projects_service.dart';
import '../project_detail_page.dart';
import '../../../core/api_client.dart';

class ProjectCard extends StatefulWidget {
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
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  late final ApiClient _apiClient;
  late final String _baseUrl;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _baseUrl = _apiClient.baseUrl;
  }

  @override
  Widget build(BuildContext context) {
    String? thumbUrl;
    List<String> linkList = const [];

    try {
      final List imgs = (widget.project.images.isNotEmpty)
          ? (jsonDecode(widget.project.images) as List)
          : const [];
      // Filtrar solo URLs válidas
      final validImgs = imgs
          .map((e) => e.toString())
          .where((url) => url.isNotEmpty && 
                         (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('/')))
          .toList();
      if (validImgs.isNotEmpty) {
        final imgPath = validImgs.first;
        if (imgPath.isNotEmpty) {
          // Si la URL ya es absoluta, usar tal cual (especialmente URLs de Firebase Storage)
          if (imgPath.startsWith('http://') || imgPath.startsWith('https://')) {
            thumbUrl = imgPath;
          } else if (imgPath.contains('://127.0.0.1:') && _baseUrl.contains('10.0.2.2')) {
            // Solo para desarrollo local en Android
            thumbUrl = imgPath.replaceFirst('://127.0.0.1:', '://10.0.2.2:');
          } else {
            // URL relativa, convertir a absoluta
            thumbUrl = '$_baseUrl$imgPath';
          }
        }
      }

      final List lnks = (widget.project.links.isNotEmpty)
          ? (jsonDecode(widget.project.links) as List)
          : const [];
      linkList = lnks.map((e) => e.toString()).toList(growable: false);
    } catch (_) {}

    final isLightMode = Theme.of(context).brightness == Brightness.light;
    
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
                    const Color(0xFFF0F9FF).withOpacity(0.5), // Azul pastel muy suave
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            if (thumbUrl != null && thumbUrl.isNotEmpty)
              _ProjectThumbnail(thumbUrl: thumbUrl),
            if (thumbUrl != null) const SizedBox(height: 5),
            _ProjectHeader(
              project: widget.project,
              linkList: linkList,
              isLoggedIn: widget.isLoggedIn,
              isExploreMode: widget.isExploreMode,
              onShare: widget.onShare,
              onEdit: widget.onEdit,
              onDelete: widget.onDelete,
            ),
            const SizedBox(height: 3),
            _ProjectInfo(project: widget.project),
            const SizedBox(height: 3),
            Align(
              alignment: Alignment.bottomRight,
              child: _ProjectDetailButton(projectId: widget.project.id),
            ),
          ],
        ),
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

  final String projectId;

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
