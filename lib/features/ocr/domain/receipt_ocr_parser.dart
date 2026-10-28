import 'ocr_result.dart';

class ReceiptOcrParser {
  /// Converts Bengali digits to standard Western Arabic digits (0-9)
  static String normalizeDigits(String text) {
    const bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    String result = text;
    for (int i = 0; i < bengaliDigits.length; i++) {
      result = result.replaceAll(bengaliDigits[i], i.toString());
    }
    return result;
  }

  /// Parses raw text extracted by OCR into structured fuel receipt / odometer data
  static OcrReceiptData parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return const OcrReceiptData();
    }

    final normalized = normalizeDigits(rawText);
    final lines = normalized
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    double? detectedQuantity;
    double? detectedPrice;
    double? detectedTotal;
    double? detectedOdometer;
    DateTime? detectedDate;
    String? detectedStation;
    String? detectedFuelType;
    final Map<String, String> snippets = {};

    // 1. Detect Fuel Type
    final lowerRaw = normalized.toLowerCase();
    if (lowerRaw.contains('octane') || lowerRaw.contains('অকটেন')) {
      detectedFuelType = 'octane';
    } else if (lowerRaw.contains('petrol') || lowerRaw.contains('পেট্রোল')) {
      detectedFuelType = 'petrol';
    } else if (lowerRaw.contains('diesel') || lowerRaw.contains('ডিজেল')) {
      detectedFuelType = 'diesel';
    } else if (lowerRaw.contains('cng') || lowerRaw.contains('সিএনজি')) {
      detectedFuelType = 'cng';
    } else if (lowerRaw.contains('lpg') || lowerRaw.contains('এলপিজি')) {
      detectedFuelType = 'lpg';
    }

    // 2. Detect Station Name
    // Usually located in the top 4 lines
    final stationKeywords = [
      'filling station',
      'filling',
      'petroleum',
      'station',
      'cng',
      'pump',
      'padma',
      'meghna',
      'jamuna',
      'fuel',
      'oil',
      'refuel',
      'shell',
      'total',
      'caltex',
      'standard',
      'ফিলিং স্টেশন',
      'ফিলিং',
      'পেট্রোলিয়াম',
      'স্টেশন',
      'সিএনজি',
      'পাম্প',
      'পদ্মা',
      'মেঘনা',
      'যমুনা',
      'জ্বালানি',
      'তেল',
    ];

    for (int i = 0; i < lines.length && i < 4; i++) {
      final lineLower = lines[i].toLowerCase();
      final hasKeyword = stationKeywords.any((kw) => lineLower.contains(kw));
      final hasOnlyNumbers = RegExp(r'^[0-9\s\.\:\-\/]+$').hasMatch(lines[i]);

      if (hasKeyword && !hasOnlyNumbers && lines[i].length > 3) {
        detectedStation = lines[i];
        snippets['station'] = lines[i];
        break;
      }
    }

    // 3. Detect Date
    // Matches YYYY-MM-DD, DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
    final dateRegExp = RegExp(
      r'(\b\d{1,4}[-/\.]\d{1,2}[-/\.]\d{1,4}\b)',
    );
    for (final line in lines) {
      final match = dateRegExp.firstMatch(line);
      if (match != null) {
        final dateStr = match.group(1)!;
        final parsed = _tryParseDate(dateStr);
        if (parsed != null) {
          detectedDate = parsed;
          snippets['date'] = dateStr;
          break;
        }
      }
    }

    // 4. Line-by-line label matching
    for (final line in lines) {
      final lower = line.toLowerCase();

      // Odometer patterns
      if (detectedOdometer == null &&
          (lower.contains('odo') ||
              lower.contains('odometer') ||
              lower.contains('reading') ||
              lower.contains('কিমি') ||
              lower.contains('মিটার') ||
              RegExp(r'\b\d{4,7}\s*km\b', caseSensitive: false).hasMatch(lower))) {
        final odoMatch = RegExp(r'(\d{4,7}(?:\.\d+)?)').firstMatch(line);
        if (odoMatch != null) {
          final val = double.tryParse(odoMatch.group(1)!);
          if (val != null && val > 100) {
            detectedOdometer = val;
            snippets['odometer'] = line;
          }
        }
      }

      // Quantity / Volume patterns
      if (detectedQuantity == null &&
          (lower.contains('qty') ||
              lower.contains('quantity') ||
              lower.contains('vol') ||
              lower.contains('volume') ||
              lower.contains('ltr') ||
              lower.contains('litre') ||
              lower.contains('liter') ||
              lower.contains('লিটার') ||
              lower.contains('পরিমাণ'))) {
        final val = _extractLastDecimal(line);
        if (val != null && val > 0 && val < 1000) {
          detectedQuantity = val;
          snippets['quantity'] = line;
        }
      }

      // Rate / Unit Price patterns
      if (detectedPrice == null &&
          (lower.contains('rate') ||
              lower.contains('price/l') ||
              lower.contains('rate/l') ||
              lower.contains('unit price') ||
              (lower.contains('price') && !lower.contains('total')) ||
              lower.contains('দর') ||
              lower.contains('@'))) {
        final val = _extractLastDecimal(line);
        if (val != null && val > 0 && val < 1000) {
          detectedPrice = val;
          snippets['price'] = line;
        }
      }

      // Total Cost patterns
      if (detectedTotal == null &&
          (lower.contains('total') ||
              lower.contains('grand') ||
              lower.contains('amount') ||
              lower.contains('net') ||
              lower.contains('টাকা') ||
              lower.contains('মোট'))) {
        final val = _extractLastDecimal(line);
        if (val != null && val > 0) {
          detectedTotal = val;
          snippets['total'] = line;
        }
      }
    }

    // 5. If labels weren't explicitly found, search for standalone numbers and cross-reconcile
    if (detectedQuantity == null || detectedPrice == null || detectedTotal == null) {
      final allDecimals = _extractAllDecimals(lines);

      // Try finding 3 numbers a, b, c where a * b ≈ c
      for (int i = 0; i < allDecimals.length; i++) {
        for (int j = 0; j < allDecimals.length; j++) {
          if (i == j) continue;
          final a = allDecimals[i];
          final b = allDecimals[j];
          final prod = a * b;

          for (int k = 0; k < allDecimals.length; k++) {
            if (k == i || k == j) continue;
            final c = allDecimals[k];

            if ((prod - c).abs() <= 1.0 || (c > 0 && (prod - c).abs() / c < 0.02)) {
              // We found a math match: a * b = c!
              // Typically: Quantity is smaller than Price or Price is standard fuel price (40 - 250)
              double q, p, t;
              t = c;
              if (a > 30 && a < 250 && b < 150) {
                p = a;
                q = b;
              } else if (b > 30 && b < 250 && a < 150) {
                p = b;
                q = a;
              } else {
                q = a < b ? a : b;
                p = a < b ? b : a;
              }

              detectedQuantity ??= q;
              detectedPrice ??= p;
              detectedTotal ??= t;
              snippets['math_cross_calc'] = '$q × $p ≈ $t';
              break;
            }
          }
        }
      }
    }

    // 6. Direct 2-of-3 deduction if 2 are known
    if (detectedQuantity != null && detectedPrice != null && detectedTotal == null) {
      detectedTotal = double.parse((detectedQuantity * detectedPrice).toStringAsFixed(2));
    } else if (detectedTotal != null && detectedPrice != null && detectedPrice > 0 && detectedQuantity == null) {
      detectedQuantity = double.parse((detectedTotal / detectedPrice).toStringAsFixed(2));
    } else if (detectedTotal != null && detectedQuantity != null && detectedQuantity > 0 && detectedPrice == null) {
      detectedPrice = double.parse((detectedTotal / detectedQuantity).toStringAsFixed(2));
    }

    // 7. If odometer is still missing and text looks like an odometer screen capture
    // (a standalone line with 4-7 digits, ignoring clock times)
    if (detectedOdometer == null) {
      for (final line in lines) {
        final lower = line.toLowerCase();
        final isTime = RegExp(r'\b\d{1,2}:\d{2}\b').hasMatch(line) ||
            lower.contains('am') ||
            lower.contains('pm');
        if (isTime) continue;

        final clean = line.replaceAll(RegExp(r'[^0-9\.]'), '');
        final val = double.tryParse(clean);
        if (val != null &&
            val >= 1000 &&
            val <= 9999999 &&
            val != detectedQuantity &&
            val != detectedPrice &&
            val != detectedTotal) {
          detectedOdometer = val;
          snippets['odometer_fallback'] = line;
          break;
        }
      }
    }

    // Calculate confidence score (0.0 to 1.0)
    int scoreCount = 0;
    if (detectedQuantity != null) scoreCount++;
    if (detectedPrice != null) scoreCount++;
    if (detectedTotal != null) scoreCount++;
    if (detectedOdometer != null) scoreCount++;
    if (detectedStation != null) scoreCount++;
    if (detectedDate != null) scoreCount++;

    final double confidence = scoreCount > 0 ? (scoreCount / 4.0).clamp(0.2, 1.0) : 0.0;

    return OcrReceiptData(
      odometer: detectedOdometer,
      quantity: detectedQuantity,
      pricePerUnit: detectedPrice,
      totalCost: detectedTotal,
      date: detectedDate,
      stationName: detectedStation,
      fuelType: detectedFuelType,
      confidence: confidence,
      rawText: rawText,
      detectedSnippets: snippets,
    );
  }

  static double? _extractLastDecimal(String text) {
    final matches = RegExp(r'(\d+(?:\.\d+)?)').allMatches(text);
    if (matches.isEmpty) return null;
    return double.tryParse(matches.last.group(1)!);
  }

  static List<double> _extractAllDecimals(List<String> lines) {
    final List<double> numbers = [];
    for (final line in lines) {
      final matches = RegExp(r'(\d+(?:\.\d+)?)').allMatches(line);
      for (final m in matches) {
        final val = double.tryParse(m.group(1)!);
        if (val != null && val > 0 && !numbers.contains(val)) {
          numbers.add(val);
        }
      }
    }
    return numbers;
  }

  static DateTime? _tryParseDate(String str) {
    try {
      final parts = str.split(RegExp(r'[-/\.]'));
      if (parts.length != 3) return null;

      int year, month, day;
      if (parts[0].length == 4) {
        // YYYY-MM-DD
        year = int.parse(parts[0]);
        month = int.parse(parts[1]);
        day = int.parse(parts[2]);
      } else if (parts[2].length == 4) {
        // DD/MM/YYYY
        day = int.parse(parts[0]);
        month = int.parse(parts[1]);
        year = int.parse(parts[2]);
      } else {
        // Assume 2-digit year or DD/MM/YY
        day = int.parse(parts[0]);
        month = int.parse(parts[1]);
        year = 2000 + int.parse(parts[2]);
      }

      if (month < 1 || month > 12 || day < 1 || day > 31) return null;
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }
}
