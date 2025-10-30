import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/portfolio/portfolio_page.dart';
import 'features/jobs/jobs_page.dart';
import 'features/ai/widgets/career_chat_sheet.dart';
import 'features/auth/ui/auth_page.dart';
import 'features/auth/data/auth_store.dart';

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
