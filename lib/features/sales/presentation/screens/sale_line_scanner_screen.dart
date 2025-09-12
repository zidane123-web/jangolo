import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SaleLineScannerScreen extends StatefulWidget {
  final int targetQuantity;
  final List<String> alreadyScannedCodes;
  final String articleName;

  const SaleLineScannerScreen({
    super.key,
    required this.targetQuantity,
    required this.alreadyScannedCodes,
    required this.articleName,
  });

  @override
  State<SaleLineScannerScreen> createState() => _SaleLineScannerScreenState();
}

class _SaleLineScannerScreenState extends State<SaleLineScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  late final List<String> _scannedCodes;
  Timer? _scanDebouncer;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _scannedCodes = List.from(widget.alreadyScannedCodes);
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

    if (_scannedCodes.length >= widget.targetQuantity) return;

    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code != null && code.trim().isNotEmpty) {
      if (!_scannedCodes.contains(code)) {
        setState(() {
          _scannedCodes.add(code);
        });
        _showFeedback('Code ajouté !', isSuccess: true);
      } else {
        _showFeedback('Ce code a déjà été scanné.', isError: true);
      }
    }
  }

  void _removeCode(int index) {
    setState(() {
      _scannedCodes.removeAt(index);
    });
  }

  void _showFeedback(String message, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.orange
            : (isSuccess ? Colors.green : null),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isComplete =
        _scannedCodes.length == widget.targetQuantity;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.articleName),
        leading:
            BackButton(onPressed: () => Navigator.of(context).pop(_scannedCodes)),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? Colors.yellow.shade700 : null,
            ),
            onPressed: () {
              _cameraController.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
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
                color: Colors.black.withOpacity(0.7),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Text(
                      'Scannés: ${_scannedCodes.length} / ${widget.targetQuantity}',
                      style: TextStyle(
                        color: isComplete ? Colors.greenAccent : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _scannedCodes.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                                'Veuillez scanner les codes...',
                                style: TextStyle(color: Colors.white70)),
                          )
                        : ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxHeight: 120),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _scannedCodes.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                          child: Text(
                                              "• ${_scannedCodes[index]}",
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12))),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                            size: 20),
                                        onPressed: () => _removeCode(index),
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
                color: Colors.black.withOpacity(0.7),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_scannedCodes),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor:
                          isComplete ? Colors.green : Colors.blue,
                    ),
                    child: Text(isComplete
                        ? 'Valider les codes'
                        : 'Valider (${_scannedCodes.length}/${widget.targetQuantity})'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
