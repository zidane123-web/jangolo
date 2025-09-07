import 'package:flutter/material.dart';

import '../../domain/entities/article_entity.dart';
import '../../domain/usecases/add_article.dart';

class CreateArticleScreen extends StatefulWidget {
  final AddArticle addArticle;
  final String organizationId;

  const CreateArticleScreen({
    super.key,
    required this.addArticle,
    required this.organizationId,
  });

  @override
  State<CreateArticleScreen> createState() => _CreateArticleScreenState();
}

class _CreateArticleScreenState extends State<CreateArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  ArticleCategory? _category;
  bool _trackCodes = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final entity = ArticleEntity(
      id: '',
      name: _nameCtrl.text.trim(),
      category: _category!,
      buyPrice: 0,
      sellPrice: 0,
      hasSerializedUnits: _trackCodes,
      totalQuantity: 0,
      createdAt: DateTime.now(),
    );
    final created = await widget.addArticle(widget.organizationId, entity);
    if (mounted) Navigator.pop(context, created);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un article')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            24,
            16,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nom requis' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ArticleCategory>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: ArticleCategory.values
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v),
                  validator: (v) => v == null ? 'Catégorie requise' : null,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Traquer les codes scannés'),
                  value: _trackCodes,
                  onChanged: (v) => setState(() => _trackCodes = v),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Créer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
