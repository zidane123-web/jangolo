import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  final int codesPerItem;
  final List<List<String>> alreadyScannedGroups;

  const QRScannerScreen({
    super.key,
    required this.codesPerItem,
    required this.alreadyScannedGroups,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  
  late final List<List<String>> _validatedGroups;
  final List<String> _currentGroup = [];
  bool _isTorchOn = false;
  Timer? _scanDebouncer;

  @override
  void initState() {
    super.initState();
    _validatedGroups = List.from(widget.alreadyScannedGroups.map((g) => List<String>.from(g)));
  }

  @override
  void dispose() {
    _scanDebouncer?.cancel();
    _cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanDebouncer?.isActive ?? false) return;
    _scanDebouncer = Timer(const Duration(milliseconds: 500), () {});

    final allScannedCodes = _validatedGroups.expand((group) => group).toList()..addAll(_currentGroup);
    int codesAdded = 0;

    for (var barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.trim().isNotEmpty) {
        // La seule condition pour ajouter est d'être un code unique
        if (!allScannedCodes.contains(code)) {
          _currentGroup.add(code);
          allScannedCodes.add(code); // On l'ajoute à la liste de vérification
          codesAdded++;
        }
      }
    }

    if (codesAdded > 0) {
      setState(() {});
      _showFeedback('$codesAdded code(s) ajouté(s)');
    }
  }

  void _validateCurrentGroup() {
    if (_currentGroup.length != widget.codesPerItem) return;
    setState(() {
      _validatedGroups.add(List.from(_currentGroup));
      _currentGroup.clear();
    });
    _showFeedback('Article validé ! Prêt pour le suivant.', isSuccess: true);
  }
  
  void _removeCodeFromCurrentGroup(int index) {
    setState(() {
      _currentGroup.removeAt(index);
    });
  }
  
  void _showFeedback(String message, {bool isError = false, bool isSuccess = false}) {
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.orange : (isSuccess ? Colors.green : null),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final totalValidatedCount = _validatedGroups.length;
    
    // ✅ --- LOGIQUE D'ÉTAT POUR LE BOUTON ET L'AFFICHAGE ---
    final int currentCount = _currentGroup.length;
    final int expectedCount = widget.codesPerItem;
    final bool isCountCorrect = currentCount == expectedCount;
    final bool isOverflown = currentCount > expectedCount;

    String buttonText;
    Color counterColor = Colors.white;
    if (isOverflown) {
      buttonText = 'Supprimez ${currentCount - expectedCount} code(s) en trop';
      counterColor = Colors.redAccent;
    } else if (isCountCorrect) {
      buttonText = 'Valider cet article';
    } else {
      buttonText = 'En attente de ${expectedCount - currentCount} code(s)...';
    }
    // --- FIN DE LA LOGIQUE D'ÉTAT ---

    return Scaffold(
      appBar: AppBar(
        title: Text('Scan (Produit ${totalValidatedCount + 1})'),
        leading: BackButton(onPressed: () => Navigator.of(context).pop(_validatedGroups)),
         actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? Colors.yellow : Colors.grey,
            ),
            onPressed: () {
              _cameraController.toggleTorch();
              setState(() { _isTorchOn = !_isTorchOn; });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                color: Colors.black.withAlpha(200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Text(
                      'Lot actuel ($currentCount / $expectedCount)',
                      style: TextStyle(color: counterColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    _currentGroup.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text('Pointez la caméra vers les codes QR...', style: TextStyle(color: Colors.white70)),
                          )
                        : ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 120),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _currentGroup.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text("• ${_currentGroup[index]}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                        onPressed: () => _removeCodeFromCurrentGroup(index),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),
              
              Container(
                padding: const EdgeInsets.all(20.0),
                color: Colors.black.withAlpha(200),
                child: Column(
                  children: [
                    Text(
                      '$totalValidatedCount article(s) déjà validé(s)',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isCountCorrect ? _validateCurrentGroup : null, // ✅ Le bouton n'est actif que si le compte est bon
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                          disabledBackgroundColor: Colors.grey.shade700,
                        ),
                        child: Text(buttonText),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}