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
      // shareUrl is already absolute from service
      if (!context.mounted) return;
      final fullUrl = shareUrl;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Compartir mi portafolio'),
          contentPadding: const EdgeInsets.all(16),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Comparte todos tus proyectos con este enlace:'),
                  const SizedBox(height: 12),
                  SelectableText(fullUrl),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: QrImageView(
                      data: fullUrl,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ],
              ),
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
      // Primero compartir el portafolio para asegurar que el token existe
      final shareUrl = await service.sharePortfolio();
      // Extraer el token de la URL (puede ser absoluta o relativa)
      String token = '';
      try {
        // Si es URL absoluta: https://.../share/pf/<token>
        // Si es URL relativa: /share/pf/<token>
        final uri = Uri.parse(shareUrl);
        final pathSegments = uri.pathSegments;
        // Buscar 'pf' y tomar el siguiente segmento (el token)
        final pfIndex = pathSegments.indexOf('pf');
        if (pfIndex >= 0 && pfIndex < pathSegments.length - 1) {
          token = pathSegments[pfIndex + 1];
        } else {
          // Fallback: tomar el último segmento
          token = pathSegments.isNotEmpty ? pathSegments.last : '';
        }
        // Limpiar posibles parámetros de query
        if (token.contains('?')) {
          token = token.split('?').first;
        }
      } catch (e) {
        // Fallback simple si el parseo falla
        final parts = shareUrl.split('/');
        token = parts.last;
        if (token.contains('?')) {
          token = token.split('?').first;
        }
      }
      
      if (token.isEmpty) {
        throw Exception('No se pudo extraer el token del enlace de compartir');
      }
      
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

