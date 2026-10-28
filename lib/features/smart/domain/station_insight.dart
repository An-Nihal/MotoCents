class StationInsight {
  final String stationName;
  final int visitCount;
  final double totalVolume;
  final double totalSpend;
  final double averagePrice;
  final double minPrice;
  final double maxPrice;
  final double? averageMileage;
  final DateTime lastVisited;
  final bool isBestMileage;
  final bool isLowestPrice;
  final double? mileageDiffVsAvg;

  const StationInsight({
    required this.stationName,
    required this.visitCount,
    required this.totalVolume,
    required this.totalSpend,
    required this.averagePrice,
    required this.minPrice,
    required this.maxPrice,
    this.averageMileage,
    required this.lastVisited,
    this.isBestMileage = false,
    this.isLowestPrice = false,
    this.mileageDiffVsAvg,
  });

  String get formattedDiff {
    if (mileageDiffVsAvg == null) return '';
    final sign = mileageDiffVsAvg! >= 0 ? '+' : '';
    return '$sign${mileageDiffVsAvg!.toStringAsFixed(1)}';
  }
}

class StationInsightsSummary {
  final List<StationInsight> stations;
  final StationInsight? bestMileageStation;
  final StationInsight? lowestPriceStation;
  final double vehicleAverageMileage;
  final double vehicleAveragePrice;

  const StationInsightsSummary({
    this.stations = const [],
    this.bestMileageStation,
    this.lowestPriceStation,
    this.vehicleAverageMileage = 0.0,
    this.vehicleAveragePrice = 0.0,
  });

  bool get isEmpty => stations.isEmpty;
}
