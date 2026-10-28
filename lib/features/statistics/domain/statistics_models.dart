import 'package:flutter/material.dart';

enum StatisticsPeriod {
  threeMonths('3 Months', 90),
  sixMonths('6 Months', 180),
  oneYear('1 Year', 365),
  allTime('All Time', null);

  final String label;
  final int? days;
  const StatisticsPeriod(this.label, this.days);

  DateTime? getStartDate(DateTime now) {
    if (days == null) return null;
    return now.subtract(Duration(days: days!));
  }
}

class MonthlySpendData {
  final int year;
  final int month;
  final String monthLabel;
  final double fuelCost;
  final double serviceCost;
  final double otherExpensesCost;

  const MonthlySpendData({
    required this.year,
    required this.month,
    required this.monthLabel,
    this.fuelCost = 0.0,
    this.serviceCost = 0.0,
    this.otherExpensesCost = 0.0,
  });

  double get totalCost => fuelCost + serviceCost + otherExpensesCost;

  MonthlySpendData copyWith({
    double? fuelCost,
    double? serviceCost,
    double? otherExpensesCost,
  }) {
    return MonthlySpendData(
      year: year,
      month: month,
      monthLabel: monthLabel,
      fuelCost: fuelCost ?? this.fuelCost,
      serviceCost: serviceCost ?? this.serviceCost,
      otherExpensesCost: otherExpensesCost ?? this.otherExpensesCost,
    );
  }
}

class CostBreakdownItem {
  final String label;
  final double amount;
  final double percentage;
  final Color color;
  final IconData? icon;

  const CostBreakdownItem({
    required this.label,
    required this.amount,
    required this.percentage,
    required this.color,
    this.icon,
  });
}

class MileageTrendPoint {
  final DateTime date;
  final double mileage;
  final double odometer;
  final String formattedDate;

  const MileageTrendPoint({
    required this.date,
    required this.mileage,
    required this.odometer,
    required this.formattedDate,
  });
}

class VehicleStatisticsSummary {
  final double totalSpend;
  final double totalFuelSpend;
  final double totalServiceSpend;
  final double totalOtherSpend;
  final double totalDistance;
  final double costPerDistance;
  final double costPerDay;
  final double avgMileage;
  final double bestMileage;
  final double worstMileage;
  final int totalFillUps;
  final int totalServices;
  final int totalExpenses;
  final List<MonthlySpendData> monthlyTrends;
  final List<CostBreakdownItem> tcoBreakdown;
  final List<CostBreakdownItem> expenseCategoryBreakdown;
  final List<MileageTrendPoint> mileageTrend;

  const VehicleStatisticsSummary({
    this.totalSpend = 0.0,
    this.totalFuelSpend = 0.0,
    this.totalServiceSpend = 0.0,
    this.totalOtherSpend = 0.0,
    this.totalDistance = 0.0,
    this.costPerDistance = 0.0,
    this.costPerDay = 0.0,
    this.avgMileage = 0.0,
    this.bestMileage = 0.0,
    this.worstMileage = 0.0,
    this.totalFillUps = 0,
    this.totalServices = 0,
    this.totalExpenses = 0,
    this.monthlyTrends = const [],
    this.tcoBreakdown = const [],
    this.expenseCategoryBreakdown = const [],
    this.mileageTrend = const [],
  });
}
