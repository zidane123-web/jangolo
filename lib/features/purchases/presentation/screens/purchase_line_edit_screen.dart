// lib/features/purchases/presentation/screens/purchase_line_edit_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../inventory/data/models/article.dart';
import '../../../inventory/data/datasources/inventory_remote_datasource.dart';
import '../../../inventory/data/repositories/inventory_repository_impl.dart';
import '../../../inventory/domain/entities/article_entity.dart';
import '../../../inventory/domain/usecases/add_article.dart';
import '../../../inventory/domain/usecases/get_articles.dart';
import '../../../inventory/presentation/screens/create_article_screen.dart';
import '../widgets/create_purchase/form_widgets.dart'; // Pour le PickerField

import '../../domain/entities/purchase_line_entity.dart';
import 'qr_scanner_screen.dart';


class LineItem {
  final String name;
  final String? sku;
  final List<List<String>> scannedCodeGroups;
  final double unitPrice;
  final DiscountType discountType;
  final double discountValue;
  final double vatRate;
  final int codesPerItem;
  final int? manualQty;

  LineItem({
    required this.name,
    this.sku,
    this.scannedCodeGroups = const [],
    required this.unitPrice,
    this.discountType = DiscountType.none,
    this.discountValue = 0.0,
    required this.vatRate,
    this.codesPerItem = 1,
    this.manualQty,
  });

  num get qty => manualQty ?? scannedCodeGroups.length;
  num get gross => qty * unitPrice;
  num get lineDiscount {
    switch (discountType) {
      case DiscountType.none: return 0;
      case DiscountType.percent: return gross * (discountValue / 100.0);
      case DiscountType.fixed: return discountValue.clamp(0, gross);
    }
  }
  num get lineSubtotal => (gross - lineDiscount).clamp(0, double.infinity);
  num get lineTax => lineSubtotal * vatRate;
  num get lineTotal => lineSubtotal + lineTax;
}

class PurchaseLineEditScreen extends StatefulWidget {
  final LineItem? initial;
  final String currency;

  const PurchaseLineEditScreen({
    super.key,
    this.initial,
    required this.currency,
  });

  @override
  State<PurchaseLineEditScreen> createState() => _PurchaseLineEditScreenState();
}

class _PurchaseLineEditScreenState extends State<PurchaseLineEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // ✅ --- MODIFICATION: Le controller de nom est remplacé par un Article ---
  Article? _selectedArticle;
  // --- FIN MODIFICATION ---

  late final AddArticle _addArticle;
  late final GetArticles _getArticles;
  StreamSubscription<List<ArticleEntity>>? _articlesSub;
  String? _organizationId;

  late final TextEditingController _unitPrice;
  late DiscountType _discountType = widget.initial?.discountType ?? DiscountType.none;
  late final TextEditingController _discountValue = TextEditingController(text: _fmtNum(widget.initial?.discountValue ?? 0));
  late final TextEditingController _vatRate = TextEditingController(text: ((widget.initial?.vatRate ?? 0.18) * 100).toStringAsFixed(0));
  late final TextEditingController _codesPerItemCtrl = TextEditingController(text: widget.initial?.codesPerItem.toString() ?? '1');
  late List<List<String>> _scannedCodeGroups = widget.initial?.scannedCodeGroups ?? [];
  late final TextEditingController _quantityCtrl = TextEditingController(text: (widget.initial?.manualQty ?? widget.initial?.qty)?.toString() ?? '1');

  // ✅ Liste des articles disponibles chargés depuis Firestore
  final List<Article> _availableArticles = [];

  @override
  void initState() {
    super.initState();
    final remoteDataSource = InventoryRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
    final repository = InventoryRepositoryImpl(remoteDataSource: remoteDataSource);
    _addArticle = AddArticle(repository);
    _getArticles = GetArticles(repository);

    _unitPrice = TextEditingController(text: _fmtNum(widget.initial?.unitPrice ?? 0));

    _setupArticlesStream();
  }

  @override
  void dispose() {
    _articlesSub?.cancel();
    _unitPrice.dispose();
    _discountValue.dispose();
    _vatRate.dispose();
    _codesPerItemCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _setupArticlesStream() async {
    final orgId = await _getOrganizationId();
    _organizationId = orgId;
    _articlesSub = _getArticles(orgId).listen((entities) {
      setState(() {
        _availableArticles
          ..clear()
          ..addAll(entities.map((e) => Article(
                category: e.category,
                name: e.name,
                sku: e.id,
                buyPrice: e.buyPrice,
                sellPrice: e.sellPrice,
                qty: e.totalQuantity,
                hasSerializedUnits: e.hasSerializedUnits,
              )));
      });
      if (widget.initial != null && _selectedArticle == null) {
        try {
          _selectedArticle = _availableArticles.firstWhere((a) => a.name == widget.initial!.name);
          _unitPrice.text = _fmtNum(widget.initial!.unitPrice);
          if (!_selectedArticle!.hasSerializedUnits) {
            _quantityCtrl.text = (widget.initial!.manualQty ?? widget.initial!.qty).toString();
          }
        } catch (_) {}
      }
    });
  }


  String _fmtNum(num v) => NumberFormat("#,##0.##", "fr_FR").format(v);
  num _parseNum(String v) {
    final clean = v.replaceAll(' ', '').replaceAll(',', '.');
    return num.tryParse(clean) ?? 0;
  }

  Future<String> _getOrganizationId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utilisateur non authentifié.");
    final userDoc = await FirebaseFirestore.instance.collection('utilisateurs').doc(user.uid).get();
    final orgId = userDoc.data()?['organizationId'] as String?;
    if (orgId == null) throw Exception("Organisation non trouvée.");
    return orgId;
  }
  
  // ✅ --- NOUVEAU: Logique pour afficher le sélecteur d'articles ---
  void _showArticlePicker() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
      builder: (_) => _ArticlePickerSheet(
        articles: _availableArticles,
        currency: widget.currency,
          onSelected: _onArticleSelected,
          onCreate: _openCreateArticleScreen,
          fmtNum: _fmtNum,
        ),
      );
    }

    Future<void> _openCreateArticleScreen() async {
      final orgId = _organizationId ?? await _getOrganizationId();
      final created = await Navigator.of(context).push<ArticleEntity>(
        MaterialPageRoute(
          builder: (_) => CreateArticleScreen(
            addArticle: _addArticle,
            organizationId: orgId,
          ),
        ),
      );
      if (created != null) {
        final article = Article(
          category: created.category,
          name: created.name,
          sku: created.id,
          buyPrice: created.buyPrice,
          sellPrice: created.sellPrice,
          qty: created.totalQuantity,
          hasSerializedUnits: created.hasSerializedUnits,
        );
        _onArticleSelected(article);
      }
    }

    void _onArticleSelected(Article article) {
      setState(() {
        _selectedArticle = article;
        _unitPrice.text = _fmtNum(article.buyPrice);
        _scannedCodeGroups = [];
        _quantityCtrl.text = '1';
      });
    }
  
  Future<void> _openScanner() async {
    if (!_formKey.currentState!.validate()) return;
    final codesPerItem = int.tryParse(_codesPerItemCtrl.text) ?? 1;
    final result = await Navigator.of(context).push<List<List<String>>>(
      MaterialPageRoute(
        builder: (_) => QRScannerScreen(
          codesPerItem: codesPerItem,
          alreadyScannedGroups: _scannedCodeGroups,
        ),
      ),
    );
    if (result != null) {
      setState(() => _scannedCodeGroups = result);
    }
  }

  InputDecoration _m3InputDecoration(BuildContext context, {required String label, String? suffixText}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      suffixText: suffixText,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary, width: 2.0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Ajouter un article' : 'Modifier l\'article'),
        backgroundColor: Colors.white,
        elevation: 0.8,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              Text('Détails de l\'article', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              // ✅ --- MODIFICATION: Le champ de texte est remplacé par un PickerField ---
              PickerField(
                label: 'Désignation *',
                value: _selectedArticle?.name ?? 'Sélectionner un article...',
                onTap: _showArticlePicker,
                prefixIcon: Icons.inventory_2_outlined,
              ),
              // --- FIN MODIFICATION ---

              const SizedBox(height: 24),
              if (_selectedArticle?.hasSerializedUnits ?? false) ...[
                Text('Quantité par Scan', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codesPerItemCtrl,
                  decoration: _m3InputDecoration(context, label: 'Nombre de codes par article *'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if ((int.tryParse(v) ?? 0) < 1) return 'Doit être > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _ScanResultTile(
                  count: _scannedCodeGroups.length,
                  onTap: _openScanner,
                ),
              ] else ...[
                Text('Quantité', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityCtrl,
                  decoration: _m3InputDecoration(context, label: 'Quantité *'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if ((int.tryParse(v) ?? 0) < 1) return 'Doit être > 0';
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 24),

              Text('Prix, Remise et TVA', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _unitPrice,
                      decoration: _m3InputDecoration(context, label: 'Prix unitaire *', suffixText: widget.currency),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => (_parseNum(v ?? '') < 0) ? 'Doit être ≥ 0' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _vatRate,
                      decoration: _m3InputDecoration(context, label: 'TVA *', suffixText: '%'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requis';
                        final val = _parseNum(v);
                        if (val < 0) return '≥ 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<DiscountType>(
                      value: _discountType,
                      decoration: _m3InputDecoration(context, label: 'Type remise'),
                      items: const [
                        DropdownMenuItem(value: DiscountType.none, child: Text('Aucune')),
                        DropdownMenuItem(value: DiscountType.percent, child: Text('Pourcentage (%)')),
                        DropdownMenuItem(value: DiscountType.fixed, child: Text('Montant fixe')),
                      ],
                      onChanged: (v) => setState(() => _discountType = v ?? DiscountType.none),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_discountType != DiscountType.none)
                    Expanded(
                      child: TextFormField(
                        controller: _discountValue,
                        decoration: _m3InputDecoration(context, label: 'Valeur remise', suffixText: _discountType == DiscountType.percent ? '%' : widget.currency),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  if(_discountType == DiscountType.none)
                    const Spacer(),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        if (_selectedArticle == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Veuillez sélectionner un article.'), backgroundColor: Colors.redAccent),
                          );
                          return;
                        }
                        if (!_formKey.currentState!.validate()) return;

                        if (_selectedArticle!.hasSerializedUnits) {
                          if (_scannedCodeGroups.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Veuillez scanner au moins un article.'), backgroundColor: Colors.redAccent),
                            );
                            return;
                          }
                        } else {
                          final qty = int.tryParse(_quantityCtrl.text) ?? 0;
                          if (qty < 1) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Quantité invalide'), backgroundColor: Colors.redAccent),
                            );
                            return;
                          }
                          _scannedCodeGroups = List.generate(qty, (_) => <String>[]);
                        }

                        final vatPercent = _parseNum(_vatRate.text).toDouble();
                        final vatDecimal = vatPercent / 100.0;

                        final item = LineItem(
                          name: _selectedArticle!.name,
                          sku: _selectedArticle!.sku,
                          scannedCodeGroups: _scannedCodeGroups,
                          unitPrice: _parseNum(_unitPrice.text).toDouble(),
                          discountType: _discountType,
                          discountValue: _parseNum(_discountValue.text).toDouble(),
                          vatRate: vatDecimal,
                          codesPerItem: int.tryParse(_codesPerItemCtrl.text) ?? 1,
                          manualQty: _selectedArticle!.hasSerializedUnits ? null : int.tryParse(_quantityCtrl.text),
                        );
                        Navigator.pop(context, item);
                      },
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Enregistrer la ligne'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanResultTile extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _ScanResultTile({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary.withAlpha(12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.primary.withAlpha(51)),
          ),
          child: Row(
            children: [
              Icon(Icons.qr_code_scanner_rounded, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count Articles Scannés',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Appuyez pour commencer le scan',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticlePickerSheet extends StatefulWidget {
  final List<Article> articles;
  final String currency;
  final ValueChanged<Article> onSelected;
  final VoidCallback onCreate;
  final String Function(num) fmtNum;

  const _ArticlePickerSheet({
    required this.articles,
    required this.currency,
    required this.onSelected,
    required this.onCreate,
    required this.fmtNum,
  });

  @override
  State<_ArticlePickerSheet> createState() => _ArticlePickerSheetState();
}

class _ArticlePickerSheetState extends State<_ArticlePickerSheet> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.toLowerCase();
    final filteredItems = widget.articles
        .where((item) => item.name.toLowerCase().contains(query))
        .toList();
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            Text('Sélectionner un article', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Rechercher...',
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
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Aucun article trouvé.'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              widget.onCreate();
                            },
                            child: const Text('Créer un article'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(153)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: theme.colorScheme.primary.withAlpha(25),
                              child: const Icon(Icons.inventory_2_outlined, size: 20),
                            ),
                            title: Text(
                              item.name,
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text("Prix d'achat: ${widget.fmtNum(item.buyPrice)} ${widget.currency}"),
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onSelected(item);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
