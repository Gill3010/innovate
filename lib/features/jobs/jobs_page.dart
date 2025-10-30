import 'package:flutter/material.dart';
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

  late final JobsService _service;
  final FavoritesStore _store = FavoritesStore();
  Future<List<JobItem>>? _future;
  Set<String> _favorites = {};

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

  String _jobKey(JobItem j) => '${j.title}|${j.company}';

  Future<void> _search() async {
    final q = _queryCtrl.text.trim();
    final loc = _locationCtrl.text.trim();
    setState(() {
      _future = _service.search(
        q: q,
        location: loc,
        remote: _remoteOnly,
        minSalary: _minSalary,
      );
    });
    // Alerts: compare result count vs last saved count for this search key
    final key = 'q=$q|loc=$loc|remote=$_remoteOnly|min=$_minSalary';
    final results = await _future!;
    final last = await _store.loadLastCounts();
    final prev = last[key] ?? 0;
    if (results.length > prev && prev != 0 && mounted) {
      final diff = results.length - prev;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hay $diff nuevas ofertas para esta búsqueda')),
      );
    }
    await _store.saveLastCount(key, results.length);
  }

  Future<void> _saveSearch() async {
    await _store.addSavedSearch(
      q: _queryCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      remote: _remoteOnly,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Búsqueda guardada. Se te avisará si hay nuevas ofertas.')),
    );
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
                  const Text('Remoto')
                ],
              ),
              ElevatedButton.icon(
                onPressed: _search,
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
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
              : FutureBuilder<List<JobItem>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }
                    final items = snap.data ?? const <JobItem>[];
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
                          trailing: IconButton(
                            icon: Icon(isFav ? Icons.star : Icons.star_border),
                            onPressed: () async {
                              await _store.toggleFavorite(key);
                              _favorites = await _store.loadFavorites();
                              if (mounted) setState(() {});
                            },
                          ),
                          onTap: () {},
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
