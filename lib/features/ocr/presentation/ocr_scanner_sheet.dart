import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/ocr_result.dart';
import 'providers/ocr_providers.dart';

class OcrScannerSheet extends ConsumerStatefulWidget {
  final Function(OcrReceiptData data, String? imagePath) onApply;

  const OcrScannerSheet({
    super.key,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(OcrReceiptData data, String? imagePath) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => OcrScannerSheet(onApply: onApply),
    );
  }

  @override
  ConsumerState<OcrScannerSheet> createState() => _OcrScannerSheetState();
}

class _OcrScannerSheetState extends ConsumerState<OcrScannerSheet> {
  final ImagePicker _picker = ImagePicker();
  String? _selectedImagePath;
  bool _isProcessing = false;
  OcrReceiptData? _extractedData;
  String? _errorMessage;

  Future<void> _pickAndProcess(ImageSource source) async {
    setState(() {
      _errorMessage = null;
      _isProcessing = true;
    });

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (picked == null) {
        setState(() => _isProcessing = false);
        return;
      }

      setState(() {
        _selectedImagePath = picked.path;
      });

      final ocrService = ref.read(ocrServiceProvider);
      final result = await ocrService.processImage(File(picked.path));

      setState(() {
        _isProcessing = false;
        _extractedData = result;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Could not process image: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    color: AppColors.primaryAmber,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Scan (OCR)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Scan a fuel receipt or odometer cluster',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mode Selector: Camera or Gallery
            if (_selectedImagePath == null && !_isProcessing)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickAndProcess(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Take Photo'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickAndProcess(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('From Gallery'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            // Processing state
            if (_isProcessing)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Analyzing receipt text & numbers...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

            // Error display
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Extracted Results Card
            if (_extractedData != null && !_isProcessing) ...[
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryAmber.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Detected Values',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAmber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(_extractedData!.confidence * 100).toInt()}% Match',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    _buildResultRow('Quantity / Volume', _extractedData!.quantity != null ? '${_extractedData!.quantity!.toStringAsFixed(2)} L' : 'Not detected'),
                    _buildResultRow('Price per Unit', _extractedData!.pricePerUnit != null ? _extractedData!.pricePerUnit!.toStringAsFixed(2) : 'Not detected'),
                    _buildResultRow('Total Cost', _extractedData!.totalCost != null ? _extractedData!.totalCost!.toStringAsFixed(2) : 'Not detected'),
                    _buildResultRow('Odometer Reading', _extractedData!.odometer != null ? '${_extractedData!.odometer!.toStringAsFixed(0)} km' : 'Not detected'),
                    if (_extractedData!.stationName != null)
                      _buildResultRow('Station', _extractedData!.stationName!),
                    if (_extractedData!.fuelType != null)
                      _buildResultRow('Fuel Type', _extractedData!.fuelType!.toUpperCase()),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedImagePath = null;
                        _extractedData = null;
                      });
                    },
                    child: const Text('Rescan'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        widget.onApply(_extractedData!, _selectedImagePath);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Apply to Form'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryAmber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    final isDetected = value != 'Not detected';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isDetected ? FontWeight.bold : FontWeight.normal,
              color: isDetected ? null : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
