import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../expenses/domain/expense_category_helper.dart';
import '../../fuel/domain/mileage_calculator.dart';
import 'statistics_models.dart';

class StatisticsCalculator {
  static VehicleStatisticsSummary calculate({
    required List<FuelEntryData> fuelEntries,
    required List<ServiceEntryData> serviceEntries,
    required List<ExpenseData> expenses,
    required List<ExpenseCategoryData> expenseCategories,
    VehicleData? vehicle,
    StatisticsPeriod period = StatisticsPeriod.sixMonths,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final startDate = period.getStartDate(now);

    // 1. Filter by period
    final filteredFuel = startDate == null
        ? fuelEntries
        : fuelEntries.where((e) => e.entryDateTime.isAfter(startDate)).toList();

    final filteredServices = startDate == null
        ? serviceEntries
        : serviceEntries.where((e) => e.serviceDate.isAfter(startDate)).toList();

    final filteredExpenses = startDate == null
        ? expenses
        : expenses.where((e) => e.date.isAfter(startDate)).toList();

    // 2. Spending totals
    final totalFuelSpend = filteredFuel.fold<double>(0.0, (sum, e) => sum + e.totalCost);
    final totalServiceSpend = filteredServices.fold<double>(0.0, (sum, e) => sum + e.totalCost);
    final totalOtherSpend = filteredExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final totalSpend = totalFuelSpend + totalServiceSpend + totalOtherSpend;

    // 3. TCO Breakdown (Pie Chart)
    final tcoBreakdown = <CostBreakdownItem>[];
    if (totalSpend > 0) {
      if (totalFuelSpend > 0) {
        tcoBreakdown.add(
          CostBreakdownItem(
            label: 'Fuel',
            amount: totalFuelSpend,
            percentage: (totalFuelSpend / totalSpend) * 100,
            color: AppColors.primaryAmber,
            icon: Icons.local_gas_station_rounded,
          ),
        );
      }
      if (totalServiceSpend > 0) {
        tcoBreakdown.add(
          CostBreakdownItem(
            label: 'Service',
            amount: totalServiceSpend,
            percentage: (totalServiceSpend / totalSpend) * 100,
            color: AppColors.secondaryTeal,
            icon: Icons.build_circle_rounded,
          ),
        );
      }
      if (totalOtherSpend > 0) {
        tcoBreakdown.add(
          CostBreakdownItem(
            label: 'Other Expenses',
            amount: totalOtherSpend,
            percentage: (totalOtherSpend / totalSpend) * 100,
            color: Colors.purple.shade400,
            icon: Icons.payments_rounded,
          ),
        );
      }
    }

    // 4. Expenses by Category Breakdown
    final categoryMap = {for (final c in expenseCategories) c.id: c};
    final categorySpendMap = <String, double>{};

    for (final exp in filteredExpenses) {
      categorySpendMap[exp.categoryId] =
          (categorySpendMap[exp.categoryId] ?? 0.0) + exp.amount;
    }

    final expenseCategoryBreakdown = <CostBreakdownItem>[];
    final sortedCategoryEntries = categorySpendMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedCategoryEntries) {
      final category = categoryMap[entry.key];
      final catName = category?.name ?? 'Other';
      final catCode = category?.code;
      final percentage = totalOtherSpend > 0 ? (entry.value / totalOtherSpend) * 100 : 0.0;

      expenseCategoryBreakdown.add(
        CostBreakdownItem(
          label: catName,
          amount: entry.value,
          percentage: percentage,
          color: ExpenseCategoryHelper.getCategoryColor(catCode, catName),
          icon: ExpenseCategoryHelper.getCategoryIcon(catCode, catName),
        ),
      );
    }

    // 5. Monthly Spend Trends (Bar Chart)
    final monthlyMap = <String, MonthlySpendData>{};
    final monthFormat = DateFormat('MMM yyyy');

    // Pre-populate months in window
    final monthsCount = period == StatisticsPeriod.threeMonths
        ? 3
        : period == StatisticsPeriod.sixMonths
            ? 6
            : period == StatisticsPeriod.oneYear
                ? 12
                : 6;

    for (var i = monthsCount - 1; i >= 0; i--) {
      final mDate = DateTime(now.year, now.month - i, 1);
      final key = '${mDate.year}-${mDate.month.toString().padLeft(2, '0')}';
      monthlyMap[key] = MonthlySpendData(
        year: mDate.year,
        month: mDate.month,
        monthLabel: monthFormat.format(mDate),
      );
    }

    // Fill Fuel
    for (final f in filteredFuel) {
      final key = '${f.entryDateTime.year}-${f.entryDateTime.month.toString().padLeft(2, '0')}';
      if (monthlyMap.containsKey(key)) {
        final existing = monthlyMap[key]!;
        monthlyMap[key] = existing.copyWith(fuelCost: existing.fuelCost + f.totalCost);
      } else if (period == StatisticsPeriod.allTime) {
        final mDate = DateTime(f.entryDateTime.year, f.entryDateTime.month, 1);
        monthlyMap[key] = MonthlySpendData(
          year: mDate.year,
          month: mDate.month,
          monthLabel: monthFormat.format(mDate),
          fuelCost: f.totalCost,
        );
      }
    }

    // Fill Services
    for (final s in filteredServices) {
      final key = '${s.serviceDate.year}-${s.serviceDate.month.toString().padLeft(2, '0')}';
      if (monthlyMap.containsKey(key)) {
        final existing = monthlyMap[key]!;
        monthlyMap[key] = existing.copyWith(serviceCost: existing.serviceCost + s.totalCost);
      } else if (period == StatisticsPeriod.allTime) {
        final mDate = DateTime(s.serviceDate.year, s.serviceDate.month, 1);
        monthlyMap[key] = MonthlySpendData(
          year: mDate.year,
          month: mDate.month,
          monthLabel: monthFormat.format(mDate),
          serviceCost: s.totalCost,
        );
      }
    }

    // Fill Expenses
    for (final e in filteredExpenses) {
      final key = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
      if (monthlyMap.containsKey(key)) {
        final existing = monthlyMap[key]!;
        monthlyMap[key] = existing.copyWith(
          otherExpensesCost: existing.otherExpensesCost + e.amount,
        );
      } else if (period == StatisticsPeriod.allTime) {
        final mDate = DateTime(e.date.year, e.date.month, 1);
        monthlyMap[key] = MonthlySpendData(
          year: mDate.year,
          month: mDate.month,
          monthLabel: monthFormat.format(mDate),
          otherExpensesCost: e.amount,
        );
      }
    }

    final monthlyTrends = monthlyMap.values.toList()
      ..sort((a, b) {
        final cmp = a.year.compareTo(b.year);
        return cmp != 0 ? cmp : a.month.compareTo(b.month);
      });

    // 6. Fuel Mileage Trend & Stats
    final economyUnit = vehicle?.economyUnit ?? 'km/L';
    final entryStatsMap = MileageCalculator.calculateAllEntriesStats(
      entries: filteredFuel,
      economyUnit: economyUnit,
    );

    final mileageTrend = <MileageTrendPoint>[];
    final validMileages = <double>[];
    final dayFormat = DateFormat('dd MMM');

    for (final entry in filteredFuel) {
      final stat = entryStatsMap[entry.id];
      if (stat?.calculatedMileage != null) {
        final m = stat!.calculatedMileage!;
        validMileages.add(m);
        mileageTrend.add(
          MileageTrendPoint(
            date: entry.entryDateTime,
            mileage: m,
            odometer: entry.odometer,
            formattedDate: dayFormat.format(entry.entryDateTime),
          ),
        );
      }
    }

    final avgMileage = validMileages.isNotEmpty
        ? validMileages.reduce((a, b) => a + b) / validMileages.length
        : 0.0;
    final bestMileage = validMileages.isNotEmpty ? validMileages.reduce(math.max) : 0.0;
    final worstMileage = validMileages.isNotEmpty ? validMileages.reduce(math.min) : 0.0;

    // 7. Distance & Cost Efficiency
    double totalDistance = 0.0;
    if (filteredFuel.isNotEmpty) {
      final odometers = filteredFuel.map((e) => e.odometer).toList();
      final minOdo = odometers.reduce(math.min);
      final maxOdo = odometers.reduce(math.max);
      totalDistance = math.max(0.0, maxOdo - minOdo);
    }

    final costPerDistance = totalDistance > 0 ? totalSpend / totalDistance : 0.0;

    // Days in period for cost per day
    final firstDate = [
      if (filteredFuel.isNotEmpty) filteredFuel.map((e) => e.entryDateTime).reduce((a, b) => a.isBefore(b) ? a : b),
      if (filteredServices.isNotEmpty) filteredServices.map((e) => e.serviceDate).reduce((a, b) => a.isBefore(b) ? a : b),
      if (filteredExpenses.isNotEmpty) filteredExpenses.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b),
    ];

    int daysSpan = 1;
    if (firstDate.isNotEmpty) {
      final earliest = firstDate.reduce((a, b) => a.isBefore(b) ? a : b);
      daysSpan = math.max(1, now.difference(earliest).inDays);
    }

    final costPerDay = totalSpend / daysSpan;

    return VehicleStatisticsSummary(
      totalSpend: totalSpend,
      totalFuelSpend: totalFuelSpend,
      totalServiceSpend: totalServiceSpend,
      totalOtherSpend: totalOtherSpend,
      totalDistance: totalDistance,
      costPerDistance: costPerDistance,
      costPerDay: costPerDay,
      avgMileage: avgMileage,
      bestMileage: bestMileage,
      worstMileage: worstMileage,
      totalFillUps: filteredFuel.length,
      totalServices: filteredServices.length,
      totalExpenses: filteredExpenses.length,
      monthlyTrends: monthlyTrends,
      tcoBreakdown: tcoBreakdown,
      expenseCategoryBreakdown: expenseCategoryBreakdown,
      mileageTrend: mileageTrend,
    );
  }
}
