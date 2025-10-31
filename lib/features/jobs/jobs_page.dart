import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import 'data/jobs_service.dart';
import 'data/favorites_store.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  final TextEditingController _queryCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  bool _remoteOnly = false;
  int? _minSalary;
  String _sort = 'relevance'; // relevance|date|salary
  String? _selectedCountry; // Country code for LATAM

  late final JobsService _service;
  final FavoritesStore _store = FavoritesStore();
  final ApiClient _api = ApiClient();
  Future<JobsSearchResult>? _future;
  Set<String> _favorites = {};
  int? _lastTotal;

  @override
  void initState() {
    super.initState();
    _service = JobsService(ApiClient());
    _initFavs();
  }

  Future<void> _initFavs() async {
    _favorites = await _store.loadFavorites();
    if (mounted) setState(() {});
  }

  String _jobKey(JobItem j) => '${j.title}|${j.company}|${j.url}';

  Future<void> _search() async {
    final q = _queryCtrl.text.trim();
    final loc = _locationCtrl.text.trim();
    setState(() {
      _future = _service.search(
        q: q,
        location: loc,
        remote: _remoteOnly,
        minSalary: _minSalary,
        sort: _sort,
        country: _selectedCountry,
      );
    });
    // Alerts: compare result count vs last saved count for this search key
    final key = 'q=$q|loc=$loc|remote=$_remoteOnly|min=$_minSalary|sort=$_sort';
    final result = await _future!;
    _lastTotal = result.total;
    final last = await _store.loadLastCounts();
    final prev = last[key] ?? 0;
    if (result.items.length > prev && prev != 0 && mounted) {
      final diff = result.items.length - prev;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hay $diff nuevas ofertas para esta búsqueda')),
      );
    }
    await _store.saveLastCount(key, result.items.length);
    if (mounted) setState(() {});
  }

  Future<void> _saveSearch() async {
    await _store.addSavedSearch(
      q: _queryCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      remote: _remoteOnly,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Búsqueda guardada. Se te avisará si hay nuevas ofertas.',
        ),
      ),
    );
  }

  Future<void> _apply(JobItem r) async {
    try {
      await _api.post('/api/jobs/track-click', body: {
        'url': r.url,
        'title': r.title,
        'company': r.company,
        'source': r.source ?? 'adzuna',
      });
    } catch (_) {}
    final uri = Uri.tryParse(r.url);
    if (uri != null) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _queryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Puesto / Palabras clave',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación',
                    prefixIcon: Icon(Icons.place),
                  ),
                ),
              ),
              DropdownButton<String>(
                value: _selectedCountry,
                hint: const Text('País'),
                onChanged: (v) => setState(() => _selectedCountry = v),
                items: const [
                  DropdownMenuItem(value: 'mx', child: Text('🇲🇽 México')),
                  DropdownMenuItem(value: 'br', child: Text('🇧🇷 Brasil')),
                  // Otros países de LATAM aún no disponibles en Adzuna con estas credenciales
                ],
              ),
              DropdownButton<String>(
                value: _sort,
                onChanged: (v) => setState(() => _sort = v ?? 'relevance'),
                items: const [
                  DropdownMenuItem(value: 'relevance', child: Text('Relevancia')),
                  DropdownMenuItem(value: 'date', child: Text('Fecha')),
                  DropdownMenuItem(value: 'salary', child: Text('Salario')),
                ],
              ),
              SizedBox(
                width: 160,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Salario mínimo',
                    prefixIcon: Icon(Icons.payments),
                  ),
                  onChanged: (v) => _minSalary = int.tryParse(v),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: _remoteOnly,
                    onChanged: (v) => setState(() => _remoteOnly = v),
                  ),
                  const Text('Remoto'),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _search,
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
              ),
              if (_lastTotal != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text('Aprox ${_lastTotal} resultados'),
                ),
              TextButton.icon(
                onPressed: _saveSearch,
                icon: const Icon(Icons.add_alert),
                label: const Text('Guardar alerta'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _future == null
              ? const Center(child: Text('Ingresa filtros y presiona Buscar'))
              : FutureBuilder<JobsSearchResult>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }
                    final items = snap.data?.items ?? const <JobItem>[];
                    if (items.isEmpty) {
                      return const Center(child: Text('Sin resultados'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final r = items[index];
                        final key = _jobKey(r);
                        final isFav = _favorites.contains(key);
                        return ListTile(
                          tileColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                          title: Text(r.title),
                          subtitle: Text('${r.company} • ${r.location}'),
                          trailing: Wrap(spacing: 8, children: [
                            IconButton(
                              icon: Icon(isFav ? Icons.star : Icons.star_border),
                              onPressed: () async {
                                await _store.toggleFavoriteKey(
                                  key,
                                  payload: {
                                    'title': r.title,
                                    'company': r.company,
                                    'location': r.location,
                                    'url': r.url,
                                    'source': r.source ?? 'adzuna',
                                  },
                                );
                                _favorites = await _store.loadFavorites();
                                if (mounted) setState(() {});
                              },
                            ),
                            IconButton(
                              tooltip: 'Aplicar',
                              icon: const Icon(Icons.open_in_new),
                              onPressed: () => _apply(r),
                            ),
                          ]),
                          onTap: () => _apply(r),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
