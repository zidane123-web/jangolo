// lib/features/sales/presentation/screens/invoice_preview_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

class InvoicePreviewScreen extends StatefulWidget {
  final Uint8List pdfBytes;
  final String saleId;

  const InvoicePreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.saleId,
  });

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  late final PdfController _pdfController;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfController(
      document: PdfDocument.openData(widget.pdfBytes),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  Future<void> _shareInvoice() async {
    setState(() => _isSharing = true);
    try {
      // 1. Obtenir le répertoire temporaire
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/Facture_${widget.saleId.substring(0, 6)}.pdf';

      // 2. Écrire le fichier PDF
      final file = File(filePath);
      await file.writeAsBytes(widget.pdfBytes);

      // 3. Partager le fichier en utilisant share_plus
      final xfile = XFile(filePath);
      await Share.shareXFiles(
        [xfile],
        text: 'Voici la facture pour votre achat.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aperçu de la facture'),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey.shade200,
      body: Column(
        children: [
          Expanded(
            child: PdfView(
              controller: _pdfController,
              scrollDirection: Axis.vertical,
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _isSharing ? null : _shareInvoice,
              icon: _isSharing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.share_outlined),
              label: const Text('Partager'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          // Vous pouvez ajouter le bouton WhatsApp ici si vous voulez une intégration plus directe
        ],
      ),
    );
  }
}