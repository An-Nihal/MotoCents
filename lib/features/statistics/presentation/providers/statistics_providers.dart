import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/vehicles_provider.dart';
import '../../../expenses/data/expenses_repository.dart';
import '../../../expenses/presentation/providers/expenses_providers.dart';
import '../../../fuel/data/fuel_entries_repository.dart';
import '../../../service/data/services_repository.dart';
import '../../domain/statistics_calculator.dart';
import '../../domain/statistics_models.dart';

class StatisticsPeriodNotifier extends Notifier<StatisticsPeriod> {
  @override
  StatisticsPeriod build() => StatisticsPeriod.sixMonths;

  void setPeriod(StatisticsPeriod period) {
    state = period;
  }
}

final statisticsPeriodProvider =
    NotifierProvider<StatisticsPeriodNotifier, StatisticsPeriod>(
  StatisticsPeriodNotifier.new,
);

final vehicleFuelEntriesStreamProvider =
    StreamProvider.autoDispose.family<List<FuelEntryData>, String>((ref, vehicleId) {
  final repo = ref.watch(fuelEntriesRepositoryProvider);
  return repo.watchFuelEntriesForVehicle(vehicleId);
});

final vehicleServiceEntriesStreamProvider =
    StreamProvider.autoDispose.family<List<ServiceEntryWithItems>, String>((ref, vehicleId) {
  final repo = ref.watch(servicesRepositoryProvider);
  return repo.watchServiceEntriesForVehicle(vehicleId);
});

final vehicleExpensesStreamProvider =
    StreamProvider.autoDispose.family<List<ExpenseWithDetails>, String>((ref, vehicleId) {
  final repo = ref.watch(expensesRepositoryProvider);
  return repo.watchExpenses(vehicleId: vehicleId);
});

final statisticsSummaryProvider =
    Provider.autoDispose<AsyncValue<VehicleStatisticsSummary>>((ref) {
  final vehicle = ref.watch(currentVehicleProvider);
  final period = ref.watch(statisticsPeriodProvider);

  if (vehicle == null) {
    return const AsyncValue.data(VehicleStatisticsSummary());
  }

  final fuelAsync = ref.watch(vehicleFuelEntriesStreamProvider(vehicle.id));
  final serviceAsync = ref.watch(vehicleServiceEntriesStreamProvider(vehicle.id));
  final expensesAsync = ref.watch(vehicleExpensesStreamProvider(vehicle.id));
  final categoriesAsync = ref.watch(expenseCategoriesProvider);

  // If any are loading
  if (fuelAsync.isLoading ||
      serviceAsync.isLoading ||
      expensesAsync.isLoading ||
      categoriesAsync.isLoading) {
    return const AsyncValue.loading();
  }

  // If any have error
  if (fuelAsync.hasError) return AsyncValue.error(fuelAsync.error!, fuelAsync.stackTrace!);
  if (serviceAsync.hasError) return AsyncValue.error(serviceAsync.error!, serviceAsync.stackTrace!);
  if (expensesAsync.hasError) return AsyncValue.error(expensesAsync.error!, expensesAsync.stackTrace!);
  if (categoriesAsync.hasError) return AsyncValue.error(categoriesAsync.error!, categoriesAsync.stackTrace!);

  final fuelEntries = fuelAsync.value ?? [];
  final serviceEntries = (serviceAsync.value ?? []).map((s) => s.entry).toList();
  final expenses = (expensesAsync.value ?? []).map((e) => e.expense).toList();
  final categories = categoriesAsync.value ?? [];

  final summary = StatisticsCalculator.calculate(
    fuelEntries: fuelEntries,
    serviceEntries: serviceEntries,
    expenses: expenses,
    expenseCategories: categories,
    vehicle: vehicle,
    period: period,
  );

  return AsyncValue.data(summary);
});
