// lib/features/sales/data/services/invoice_generator_service.dart

import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart'; // ✅ --- IMPORT MANQUANT AJOUTÉ ICI ---

import '../../domain/entities/sale_entity.dart';

class InvoiceGeneratorService {
  /// Génère une facture en PDF à partir d'une entité de vente.
  /// Retourne le fichier PDF sous forme de bytes (Uint8List).
  static Future<Uint8List> generateInvoicePdf(SaleEntity sale) async {
    // Le thème et le document PDF de base.
    final pdf = pw.Document();

    // Pour les symboles de devise et les caractères spéciaux, il est préférable
    // de charger une police qui les supporte. Nous allons charger une police par défaut.
    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();

    pdf.addPage(
      pw.MultiPage(
        // Configuration de la page
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        // Le contenu de la page est construit ici
        build: (pw.Context context) {
          return [
            _buildHeader(sale, boldFont),
            pw.SizedBox(height: 20),
            _buildInvoiceDetails(sale, boldFont),
            pw.SizedBox(height: 20),
            _buildItemsTable(sale, font, boldFont),
            pw.Divider(height: 20, thickness: 1),
            _buildTotals(sale, boldFont),
            pw.Spacer(),
            _buildFooter(font),
          ];
        },
      ),
    );

    // Sauvegarde le document en mémoire et le retourne.
    return pdf.save();
  }

  // --- Widgets internes pour construire les parties du PDF ---

  /// Construit l'en-tête avec les infos de l'entreprise et du client.
  static pw.Widget _buildHeader(SaleEntity sale, pw.Font boldFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Jangolo Inc.', // Placeholder: Nom de l'entreprise
              style: pw.TextStyle(font: boldFont, fontSize: 20),
            ),
            pw.Text('123 Rue de la République, Cotonou'),
            pw.Text('contact@jangolo.app'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Facture pour :',
                style: const pw.TextStyle(color: PdfColors.grey700)),
            pw.Text(
              sale.customerName ?? 'Client comptant',
              style: pw.TextStyle(font: boldFont, fontSize: 16),
            ),
            // Placeholder: Ajoutez l'adresse et le contact du client si disponibles
          ],
        ),
      ],
    );
  }

  /// Construit la section avec les détails de la facture (numéro, dates).
  static pw.Widget _buildInvoiceDetails(SaleEntity sale, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Facture N°: FACT-${sale.id.substring(0, 6).toUpperCase()}',
          style: pw.TextStyle(font: boldFont, fontSize: 14),
        ),
        pw.SizedBox(height: 8),
        pw.Text('Date: ${_d(sale.createdAt)}'),
        // Placeholder: Ajoutez une date d'échéance si nécessaire
      ],
    );
  }

  /// Construit le tableau des articles vendus.
  static pw.Widget _buildItemsTable(
      SaleEntity sale, pw.Font font, pw.Font boldFont) {
    final headers = ['Description', 'Qté', 'P.U.', 'Total'];
    final data = sale.items.map((item) {
      return [
        item.name ?? 'Article',
        item.quantity.toStringAsFixed(0),
        _money(item.unitPrice),
        _money(item.lineTotal),
      ];
    }).toList();
    
    // ✅ --- CORRECTION: Utilisation de TableHelper ---
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(font: boldFont),
      cellStyle: pw.TextStyle(font: font),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
    );
  }

  /// Construit la section des totaux (sous-total, TVA, total).
  static pw.Widget _buildTotals(SaleEntity sale, pw.Font boldFont) {
    final subTotal = sale.items.fold<double>(0, (s, i) => s + i.lineSubtotal);
    final taxTotal = sale.items.fold<double>(0, (s, i) => s + i.lineTax);

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Expanded(child: pw.SizedBox()), // Espace vide à gauche
        pw.SizedBox(
          width: 200,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _totalLine('Sous-total', subTotal, boldFont),
              _totalLine('Remise', -sale.globalDiscount, boldFont),
              _totalLine('Livraison', sale.shippingFees, boldFont),
              _totalLine('TVA', taxTotal, boldFont),
              pw.Divider(color: PdfColors.grey),
              _totalLine('Total Général', sale.grandTotal, boldFont, isGrandTotal: true),
              pw.Divider(color: PdfColors.grey),
              _totalLine('Montant Payé', sale.totalPaid, boldFont),
              _totalLine('Solde Dû', sale.balanceDue, boldFont),
            ],
          ),
        )
      ],
    );
  }
  
  /// Helper pour une ligne de total.
  static pw.Widget _totalLine(String label, double value, pw.Font boldFont, {bool isGrandTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: isGrandTotal ? pw.TextStyle(font: boldFont) : null),
          pw.Text(_money(value), style: pw.TextStyle(font: boldFont)),
        ],
      ),
    );
  }
  
  /// Construit le pied de page.
  static pw.Widget _buildFooter(pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text('Merci pour votre confiance !', style: pw.TextStyle(font: font)),
        pw.SizedBox(height: 4),
        pw.Text('Jangolo Business - Votre partenaire de croissance.',
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10)),
      ],
    );
  }

  // --- Fonctions utilitaires ---
  static String _d(DateTime d) => DateFormat('dd/MM/yyyy', 'fr_FR').format(d);
  static String _money(double v) =>
      NumberFormat.currency(locale: 'fr_FR', symbol: 'F CFA', decimalDigits: 0)
          .format(v);
}