import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../domain/ocr_result.dart';
import '../domain/receipt_ocr_parser.dart';

class OcrService {
  TextRecognizer? _textRecognizer;

  TextRecognizer get textRecognizer {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizer!;
  }

  /// Processes an image from a file path using ML Kit on mobile,
  /// with safety fallback on desktop or unit test environments.
  Future<OcrReceiptData> processImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        return const OcrReceiptData();
      }

      // Check if we are running on supported mobile platforms
      final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

      if (!isMobile) {
        // In desktop/test mode, return empty or mock if file has text content
        return const OcrReceiptData(
          rawText: 'Desktop/Mock OCR: Text recognition is supported on Android and iOS devices.',
        );
      }

      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      return ReceiptOcrParser.parse(recognizedText.text);
    } catch (e) {
      debugPrint('Error during OCR processing: $e');
      return const OcrReceiptData();
    }
  }

  /// Parses text directly (useful for tests or pre-extracted blocks)
  OcrReceiptData parseText(String text) {
    return ReceiptOcrParser.parse(text);
  }

  void dispose() {
    _textRecognizer?.close();
    _textRecognizer = null;
  }
}
