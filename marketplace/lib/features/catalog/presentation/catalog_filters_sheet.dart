import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/enums.dart';
import '../../../core/widgets/primary_button.dart';
import '../../home/application/home_providers.dart';
import '../application/catalog_controller.dart';

/// Feuille de filtres du catalogue : catégorie, rayon (genre), tri.
class CatalogFiltersSheet extends ConsumerStatefulWidget {
  const CatalogFiltersSheet({super.key});

  @override
  ConsumerState<CatalogFiltersSheet> createState() =>
      _CatalogFiltersSheetState();
}

class _CatalogFiltersSheetState extends ConsumerState<CatalogFiltersSheet> {
  String? _categorySlug;
  Gender? _gender;
  String? _sort;

  static const Map<String, String> _sortKeys = {
    'newest': 'catalog.sort.newest',
    'price_asc': 'catalog.sort.priceAsc',
    'price_desc': 'catalog.sort.priceDesc',
  };

  @override
  void initState() {
    super.initState();
    final query = ref.read(catalogControllerProvider).query;
    _categorySlug = query.categorySlug;
    _gender = query.gender;
    _sort = query.sort;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = ref.watch(categoriesProvider);
    final controller = ref.read(catalogControllerProvider.notifier);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.t('catalog.filters'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            // Catégorie
            _Label(text: l10n.t('catalog.filter.category')),
            categories.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (list) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(l10n.t('common.all')),
                    selected: _categorySlug == null,
                    onSelected: (_) => setState(() => _categorySlug = null),
                  ),
                  for (final c in list)
                    ChoiceChip(
                      label: Text(c.name),
                      selected: _categorySlug == c.slug,
                      onSelected: (_) => setState(() => _categorySlug = c.slug),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Genre / rayon
            _Label(text: l10n.t('catalog.filter.gender')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.t('common.all')),
                  selected: _gender == null,
                  onSelected: (_) => setState(() => _gender = null),
                ),
                for (final g in Gender.values)
                  ChoiceChip(
                    label: Text(l10n.t(g.l10nKey)),
                    selected: _gender == g,
                    onSelected: (_) => setState(() => _gender = g),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Tri
            _Label(text: l10n.t('catalog.filter.sort')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in _sortKeys.entries)
                  ChoiceChip(
                    label: Text(l10n.t(entry.value)),
                    selected: _sort == entry.key,
                    onSelected: (_) => setState(
                      () => _sort = _sort == entry.key ? null : entry.key,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      controller.resetFilters();
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.t('catalog.filter.reset')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: l10n.t('catalog.filter.apply'),
                    onPressed: () {
                      controller.applyFilters(
                        categorySlug: _categorySlug,
                        gender: _gender,
                        sort: _sort,
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
