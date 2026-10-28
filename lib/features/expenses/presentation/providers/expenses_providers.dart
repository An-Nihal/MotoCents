import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/vehicles_provider.dart';
import '../../../documents/presentation/providers/documents_providers.dart';
import '../../data/expenses_repository.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final crypto = ref.watch(vaultCryptoServiceProvider);
  return ExpensesRepository(db, cryptoService: crypto);
});

final expensesStreamProvider =
    StreamProvider.autoDispose<List<ExpenseWithDetails>>((ref) {
  final repo = ref.watch(expensesRepositoryProvider);
  final vehicle = ref.watch(currentVehicleProvider);
  return repo.watchExpenses(vehicleId: vehicle?.id);
});

final expenseCategoriesProvider =
    StreamProvider.autoDispose<List<ExpenseCategoryData>>((ref) {
  final repo = ref.watch(expensesRepositoryProvider);
  return repo.watchCategories();
});

final monthlyExpensesSpendProvider =
    StreamProvider.autoDispose<double>((ref) {
  final repo = ref.watch(expensesRepositoryProvider);
  final vehicle = ref.watch(currentVehicleProvider);
  return repo.watchTotalExpensesThisMonth(vehicle?.id);
});
