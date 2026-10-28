import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/vehicles_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../expenses/domain/expense_category_helper.dart';
import '../../../statistics/presentation/providers/statistics_providers.dart';

enum ActivityType { fuel, service, expense }

class HomeRecentActivityItem {
  final String id;
  final ActivityType type;
  final String title;
  final String subtitle;
  final DateTime date;
  final double amount;
  final double? odometer;
  final IconData icon;
  final Color color;

  const HomeRecentActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
    this.odometer,
    required this.icon,
    required this.color,
  });
}

/// Computes combined spend for this month: Fuel + Service + Other Expenses
final homeSpendThisMonthProvider =
    Provider.autoDispose<AsyncValue<double>>((ref) {
  final vehicle = ref.watch(currentVehicleProvider);
  if (vehicle == null) return const AsyncValue.data(0.0);

  final fuelAsync = ref.watch(vehicleFuelEntriesStreamProvider(vehicle.id));
  final serviceAsync = ref.watch(vehicleServiceEntriesStreamProvider(vehicle.id));
  final expensesAsync = ref.watch(vehicleExpensesStreamProvider(vehicle.id));

  if (fuelAsync.isLoading || serviceAsync.isLoading || expensesAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (fuelAsync.hasError) return AsyncValue.error(fuelAsync.error!, fuelAsync.stackTrace!);
  if (serviceAsync.hasError) return AsyncValue.error(serviceAsync.error!, serviceAsync.stackTrace!);
  if (expensesAsync.hasError) return AsyncValue.error(expensesAsync.error!, expensesAsync.stackTrace!);

  final now = DateTime.now();
  final fuelEntries = fuelAsync.value ?? [];
  final serviceEntries = serviceAsync.value ?? [];
  final expenses = expensesAsync.value ?? [];

  final fuelThisMonth = fuelEntries.where(
    (e) => e.entryDateTime.year == now.year && e.entryDateTime.month == now.month,
  );
  final serviceThisMonth = serviceEntries.where(
    (s) => s.entry.serviceDate.year == now.year && s.entry.serviceDate.month == now.month,
  );
  final expensesThisMonth = expenses.where(
    (x) => x.expense.date.year == now.year && x.expense.date.month == now.month,
  );

  final totalFuel = fuelThisMonth.fold<double>(0.0, (sum, e) => sum + e.totalCost);
  final totalService = serviceThisMonth.fold<double>(0.0, (sum, s) => sum + s.entry.totalCost);
  final totalExpense = expensesThisMonth.fold<double>(0.0, (sum, x) => sum + x.expense.amount);

  return AsyncValue.data(totalFuel + totalService + totalExpense);
});

/// Computes unified recent activities across fuel, service, and other expenses
final homeRecentActivityProvider =
    Provider.autoDispose<AsyncValue<List<HomeRecentActivityItem>>>((ref) {
  final vehicle = ref.watch(currentVehicleProvider);
  if (vehicle == null) return const AsyncValue.data([]);

  final fuelAsync = ref.watch(vehicleFuelEntriesStreamProvider(vehicle.id));
  final serviceAsync = ref.watch(vehicleServiceEntriesStreamProvider(vehicle.id));
  final expensesAsync = ref.watch(vehicleExpensesStreamProvider(vehicle.id));

  if (fuelAsync.isLoading || serviceAsync.isLoading || expensesAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (fuelAsync.hasError) return AsyncValue.error(fuelAsync.error!, fuelAsync.stackTrace!);
  if (serviceAsync.hasError) return AsyncValue.error(serviceAsync.error!, serviceAsync.stackTrace!);
  if (expensesAsync.hasError) return AsyncValue.error(expensesAsync.error!, expensesAsync.stackTrace!);

  final List<HomeRecentActivityItem> items = [];

  // 1. Fuel entries
  for (final fuel in (fuelAsync.value ?? [])) {
    items.add(
      HomeRecentActivityItem(
        id: fuel.id,
        type: ActivityType.fuel,
        title: 'Fuel Fill-up',
        subtitle: '${fuel.quantity.toStringAsFixed(1)} ${vehicle.volumeUnit} • ${fuel.odometer.toStringAsFixed(0)} ${vehicle.distanceUnit}',
        date: fuel.entryDateTime,
        amount: fuel.totalCost,
        odometer: fuel.odometer,
        icon: Icons.local_gas_station_rounded,
        color: AppColors.primaryAmber,
      ),
    );
  }

  // 2. Service entries
  for (final s in (serviceAsync.value ?? [])) {
    final entry = s.entry;
    final itemNames = s.itemTypes.map((t) => t.name).toList();
    final title = itemNames.isNotEmpty
        ? itemNames.join(', ')
        : (entry.serviceCenter ?? 'Service Maintenance');

    items.add(
      HomeRecentActivityItem(
        id: entry.id,
        type: ActivityType.service,
        title: title,
        subtitle: 'Service • ${entry.odometer.toStringAsFixed(0)} ${vehicle.distanceUnit}',
        date: entry.serviceDate,
        amount: entry.totalCost,
        odometer: entry.odometer,
        icon: Icons.build_circle_rounded,
        color: AppColors.secondaryTeal,
      ),
    );
  }

  // 3. Other expenses
  for (final exp in (expensesAsync.value ?? [])) {
    final e = exp.expense;
    final cat = exp.category;
    final catColor = ExpenseCategoryHelper.getCategoryColor(cat.code, cat.name);
    final catIcon = ExpenseCategoryHelper.getCategoryIcon(cat.code, cat.name);

    items.add(
      HomeRecentActivityItem(
        id: e.id,
        type: ActivityType.expense,
        title: cat.name,
        subtitle: e.notes != null && e.notes!.isNotEmpty ? e.notes! : 'Other Expense',
        date: e.date,
        amount: e.amount,
        odometer: e.odometer,
        icon: catIcon,
        color: catColor,
      ),
    );
  }

  // Sort by date descending
  items.sort((a, b) => b.date.compareTo(a.date));

  // Take top 5
  return AsyncValue.data(items.take(5).toList());
});
