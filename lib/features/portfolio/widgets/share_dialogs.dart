import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ShareDialogs {
  static Future<void> showShareProjectDialog(
    BuildContext context,
    String fullUrl,
  ) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Compartir proyecto'),
        contentPadding: const EdgeInsets.all(16),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
  }

  static Future<void> showSharePortfolioDialog(
    BuildContext context,
    String fullUrl,
  ) async {
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
  }
}

