import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'features/portfolio/portfolio_page.dart';
import 'features/jobs/jobs_page.dart';
import 'features/ai/widgets/career_chat_sheet.dart';
import 'features/auth/ui/auth_page.dart';
import 'features/auth/data/auth_store.dart';
import 'features/portfolio/data/projects_service.dart';
import 'core/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'features/portfolio/public_profile_page.dart';

void main() {
  runApp(const InnovateApp());
}

class InnovateApp extends StatefulWidget {
  const InnovateApp({super.key});

  @override
  State<InnovateApp> createState() => _InnovateAppState();
}

class _InnovateAppState extends State<InnovateApp> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _authLoaded = false;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    await AuthStore.instance.load();
    if (mounted) setState(() => _authLoaded = true);
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Innovate',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('es')],
      home: _authLoaded
          ? HomeShell(onToggleTheme: _toggleTheme)
          : const SizedBox.shrink(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.onToggleTheme});
  final VoidCallback onToggleTheme;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _openAiChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.85,
        child: CareerChatSheet(),
      ),
    );
  }

  Future<void> _openAuth() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
    if (changed == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pages = [const PortfolioPage(), const JobsPage()];

    final isWide = MediaQuery.of(context).size.width >= 900;

    final navDestinations = const [
      NavigationDestination(
        icon: Icon(Icons.grid_view_outlined),
        selectedIcon: Icon(Icons.grid_view),
        label: 'Portafolio',
      ),
      NavigationDestination(
        icon: Icon(Icons.work_outline),
        selectedIcon: Icon(Icons.work),
        label: 'Empleos',
      ),
    ];

    final logged = AuthStore.instance.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Innovate'),
        actions: [
          if (_index == 0 && logged)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Opciones de portafolio',
              onSelected: (v) async {
                if (v == 'share_portfolio') {
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
                if (v == 'open_public_profile') {
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
            ),
          IconButton(
            tooltip: logged ? 'Cuenta (sesión activa)' : 'Iniciar sesión',
            onPressed: _openAuth,
            icon: Icon(logged ? Icons.verified_user : Icons.person_outline),
          ),
          IconButton(
            tooltip: 'Tema',
            onPressed: widget.onToggleTheme,
            icon: const Icon(Icons.brightness_6),
          ),
        ],
      ),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view),
                  label: Text('Portafolio'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.work_outline),
                  selectedIcon: Icon(Icons.work),
                  label: Text('Empleos'),
                ),
              ],
            ),
          Expanded(child: pages[_index]),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAiChat,
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Asesor IA'),
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              destinations: navDestinations,
              onDestinationSelected: (i) => setState(() => _index = i),
            ),
    );
  }
}
