import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/api_client.dart';
import '../data/projects_service.dart';
import '../public_profile_page.dart';

class PortfolioAppMenu extends StatelessWidget {
  const PortfolioAppMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Opciones de portafolio',
      onSelected: (v) async {
        if (v == 'share_portfolio') {
          await _sharePortfolio(context);
        }
        if (v == 'open_public_profile') {
          await _openPublicProfile(context);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'share_portfolio',
          child: Row(children: [
            Icon(Icons.share),
            SizedBox(width: 8),
            Text('Compartir mi portafolio'),
          ]),
        ),
        PopupMenuItem(
          value: 'open_public_profile',
          child: Row(children: [
            Icon(Icons.public),
            SizedBox(width: 8),
            Text('Ver mi perfil público'),
          ]),
        ),
      ],
    );
  }

  Future<void> _sharePortfolio(BuildContext context) async {
    try {
      final service = ProjectsService(ApiClient());
      final shareUrl = await service.sharePortfolio();
      final fullUrl = '${ApiClient.defaultBaseUrl}$shareUrl';
      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Compartir mi portafolio'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Comparte todos tus proyectos con este enlace:'),
                const SizedBox(height: 12),
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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al compartir: $e')),
      );
    }
  }

  Future<void> _openPublicProfile(BuildContext context) async {
    try {
      final service = ProjectsService(ApiClient());
      final shareUrl = await service.sharePortfolio();
      final token = shareUrl.split('/').last;
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PublicProfilePage(token: token),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el perfil público: $e')),
      );
    }
  }
}

