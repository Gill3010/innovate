import 'package:flutter/material.dart';

class PortfolioFilters extends StatelessWidget {
  const PortfolioFilters({
    super.key,
    required this.searchController,
    required this.category,
    required this.explore,
    required this.isLoggedIn,
    required this.onCategoryChanged,
    required this.onExploreChanged,
    required this.onRefresh,
    required this.onCreate,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final String category;
  final bool explore;
  final bool isLoggedIn;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<bool> onExploreChanged;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;
  final VoidCallback onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width < 420 ? 260 : 360,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar proyectos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Recargar',
                  icon: const Icon(Icons.refresh),
                  onPressed: onRefresh,
                ),
              ),
              onChanged: (_) => onSearchChanged(),
            ),
          ),
          DropdownButton<String>(
            value: category,
            onChanged: (v) => onCategoryChanged(v ?? 'all'),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Todos')),
              DropdownMenuItem(value: 'web', child: Text('Web')),
              DropdownMenuItem(value: 'mobile', child: Text('Móvil')),
            ],
          ),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Mis proyectos')),
              ButtonSegment(value: true, label: Text('Explorar')),
            ],
            selected: {explore},
            onSelectionChanged: (s) => onExploreChanged(s.first),
          ),
          if (isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo'),
              ),
            ),
        ],
      ),
    );
  }
}
