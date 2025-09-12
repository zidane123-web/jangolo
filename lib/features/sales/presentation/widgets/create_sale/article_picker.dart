// lib/features/sales/presentation/widgets/create_sale/article_picker.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/providers/auth_providers.dart';
import '../../../../inventory/domain/entities/article_entity.dart';
import '../../../../inventory/presentation/providers/inventory_providers.dart';

// Provider pour le texte de la recherche
final articleSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

// Provider qui exécute la recherche et retourne le flux de résultats
final articleSearchResultsProvider =
    StreamProvider.autoDispose<List<ArticleEntity>>((ref) {
  final query = ref.watch(articleSearchQueryProvider);
  final organizationId = ref.watch(organizationIdProvider).value;

  if (query.isEmpty || organizationId == null) {
    return Stream.value([]);
  }

  final searchUseCase = ref.watch(searchArticlesProvider(query));
  return searchUseCase(organizationId: organizationId, query: query);
});

Future<ArticleEntity?> showArticlePicker({
  required BuildContext context,
}) {
  return showModalBottomSheet<ArticleEntity>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    showDragHandle: true,
    builder: (context) {
      // ✅ --- CORRECTION APPLIQUÉE ICI ---
      // On encapsule le widget dans un Container pour lui donner une hauteur fixe.
      return Container(
        height: MediaQuery.of(context).size.height * 1, // 80% de la hauteur de l'écran
        child: const _ArticlePickerSheet(),
      );
      // --- FIN DE LA CORRECTION ---
    },
  );
}

class _ArticlePickerSheet extends ConsumerWidget {
  const _ArticlePickerSheet();

  String _money(double v) =>
      NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0)
          .format(v);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchResults = ref.watch(articleSearchResultsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      // ✅ --- CORRECTION APPLIQUÉE ICI ---
      // On retire `mainAxisSize: MainAxisSize.min` pour que la Column remplisse l'espace.
      child: Column(
        children: [
          Text('Sélectionner un article', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            onChanged: (query) =>
                ref.read(articleSearchQueryProvider.notifier).state = query,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ✅ --- MODIFICATION ---
          // On utilise Expanded pour que la zone de résultats prenne toute la place restante.
          Expanded(
            child: searchResults.when(
              data: (articles) {
                if (articles.isEmpty &&
                    ref.read(articleSearchQueryProvider).isEmpty) {
                  return const Center(
                      child: Text("Commencez à taper pour rechercher..."));
                }
                if (articles.isEmpty) {
                  return const Center(child: Text("Aucun article trouvé."));
                }
                return ListView.builder(
                  // On retire shrinkWrap car la hauteur est maintenant gérée par Expanded
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: theme.colorScheme.outlineVariant
                                .withAlpha(153)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.1),
                          child:
                              const Icon(Icons.inventory_2_outlined, size: 20),
                        ),
                        title: Text(article.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Stock: ${article.totalQuantity}'),
                        trailing: Text(
                          _money(article.sellPrice),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () => Navigator.pop(context, article),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text("Erreur: $e")),
            ),
          ),
        ],
      ),
    );
  }
}