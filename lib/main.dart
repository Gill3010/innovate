import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// import 'core/environment.dart';
import 'features/portfolio/portfolio_page.dart';
import 'features/jobs/jobs_page.dart';
import 'features/ai/widgets/career_chat_sheet.dart';
import 'features/auth/ui/auth_page.dart';
import 'features/auth/ui/profile_page.dart';
import 'features/auth/data/auth_store.dart';
import 'features/portfolio/widgets/portfolio_app_menu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // No inicializar Firebase en web - todo se maneja a través del backend
  // Firebase solo se necesita en apps móviles nativas si se usan características como push notifications
  // if (Environment.useFirebase && !kIsWeb) {
  //   try {
  //     await Firebase.initializeApp(
  //       options: DefaultFirebaseOptions.currentPlatform,
  //     );
  //   } catch (e) {
  //     debugPrint('Error inicializando Firebase: $e');
  //   }
  // }
  
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Indigo suave
          brightness: Brightness.light,
        ).copyWith(
          surface: const Color(0xFFFAFBFC), // Fondo suave para nav
          surfaceContainerHighest: const Color(0xFFF8F9FA), // Header
          primary: const Color(0xFF6366F1), // Botones activos
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: Color(0xFF1F2937), // Texto oscuro para contraste
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFFFAFBFC),
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(
              color: Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
        ),
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
    final logged = AuthStore.instance.isLoggedIn;
    if (logged) {
      final changed = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
      if (changed == true && mounted) setState(() {});
    } else {
      final changed = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
      if (changed == true && mounted) setState(() {});
    }
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

    final isLightMode = Theme.of(context).brightness == Brightness.light;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Innovate'),
        flexibleSpace: isLightMode
            ? Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE8F4F8), // Azul pastel claro
                      Color(0xFFF5F0FF), // Lavanda pastel
                    ],
                  ),
                ),
              )
            : null,
        actions: [
          if (_index == 0 && logged) const PortfolioAppMenu(),
          IconButton(
            tooltip: logged ? 'Mi perfil' : 'Iniciar sesión',
            onPressed: _openAuth,
            icon: Icon(logged ? Icons.person : Icons.person_outline),
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
          : isLightMode
              ? Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFAFBFC), // Beige muy claro
                        Color(0xFFFFF5F8), // Rosa pastel muy suave
                      ],
                    ),
                  ),
                  child: NavigationBar(
                    selectedIndex: _index,
                    destinations: navDestinations,
                    onDestinationSelected: (i) => setState(() => _index = i),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  ),
                )
              : NavigationBar(
                  selectedIndex: _index,
                  destinations: navDestinations,
                  onDestinationSelected: (i) => setState(() => _index = i),
                ),
    );
  }
}
