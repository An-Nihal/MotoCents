class OcrField<T> {
  final T value;
  final double confidence;
  final String rawSnippet;

  const OcrField({
    required this.value,
    this.confidence = 1.0,
    this.rawSnippet = '',
  });

  @override
  String toString() => 'OcrField(value: $value, confidence: $confidence)';
}

class OcrReceiptData {
  final double? odometer;
  final double? quantity;
  final double? pricePerUnit;
  final double? totalCost;
  final DateTime? date;
  final String? stationName;
  final String? fuelType;
  final double confidence;
  final String rawText;
  final Map<String, String> detectedSnippets;

  const OcrReceiptData({
    this.odometer,
    this.quantity,
    this.pricePerUnit,
    this.totalCost,
    this.date,
    this.stationName,
    this.fuelType,
    this.confidence = 0.0,
    this.rawText = '',
    this.detectedSnippets = const {},
  });

  bool get hasAnyValue =>
      odometer != null ||
      quantity != null ||
      pricePerUnit != null ||
      totalCost != null ||
      stationName != null;

  int get fieldsDetectedCount {
    int count = 0;
    if (odometer != null) count++;
    if (quantity != null) count++;
    if (pricePerUnit != null) count++;
    if (totalCost != null) count++;
    if (stationName != null && stationName!.isNotEmpty) count++;
    if (date != null) count++;
    return count;
  }

  OcrReceiptData copyWith({
    double? odometer,
    double? quantity,
    double? pricePerUnit,
    double? totalCost,
    DateTime? date,
    String? stationName,
    String? fuelType,
    double? confidence,
    String? rawText,
    Map<String, String>? detectedSnippets,
  }) {
    return OcrReceiptData(
      odometer: odometer ?? this.odometer,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalCost: totalCost ?? this.totalCost,
      date: date ?? this.date,
      stationName: stationName ?? this.stationName,
      fuelType: fuelType ?? this.fuelType,
      confidence: confidence ?? this.confidence,
      rawText: rawText ?? this.rawText,
      detectedSnippets: detectedSnippets ?? this.detectedSnippets,
    );
  }
}
