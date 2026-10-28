import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../documents/domain/vault_crypto_service.dart';

const _uuid = Uuid();

class ExpenseWithDetails {
  final ExpenseData expense;
  final ExpenseCategoryData category;
  final VehicleData vehicle;

  const ExpenseWithDetails({
    required this.expense,
    required this.category,
    required this.vehicle,
  });
}

class ExpensesRepository {
  final AppDatabase _db;
  final VaultCryptoService _cryptoService;

  ExpensesRepository(
    this._db, {
    VaultCryptoService? cryptoService,
  }) : _cryptoService = cryptoService ?? VaultCryptoService();

  /// Watches expenses with joined category and vehicle information.
  Stream<List<ExpenseWithDetails>> watchExpenses({
    String? vehicleId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final query = _db.select(_db.expenses).join([
      innerJoin(
        _db.expenseCategories,
        _db.expenseCategories.id.equalsExp(_db.expenses.categoryId),
      ),
      innerJoin(
        _db.vehicles,
        _db.vehicles.id.equalsExp(_db.expenses.vehicleId),
      ),
    ]);

    query.where(_db.expenses.deletedAt.isNull());

    if (vehicleId != null && vehicleId.isNotEmpty) {
      query.where(_db.expenses.vehicleId.equals(vehicleId));
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      query.where(_db.expenses.categoryId.equals(categoryId));
    }

    if (startDate != null) {
      query.where(_db.expenses.date.isBiggerOrEqualValue(startDate));
    }

    if (endDate != null) {
      query.where(_db.expenses.date.isSmallerOrEqualValue(endDate));
    }

    query.orderBy([
      OrderingTerm(expression: _db.expenses.date, mode: OrderingMode.desc),
      OrderingTerm(expression: _db.expenses.createdAt, mode: OrderingMode.desc),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return ExpenseWithDetails(
          expense: row.readTable(_db.expenses),
          category: row.readTable(_db.expenseCategories),
          vehicle: row.readTable(_db.vehicles),
        );
      }).toList();
    });
  }

  /// Watches all available expense categories.
  Stream<List<ExpenseCategoryData>> watchCategories() {
    return (_db.select(_db.expenseCategories)
          ..where((c) => c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  Future<void> createCategory(ExpenseCategoriesCompanion companion) async {
    await _db.into(_db.expenseCategories).insert(companion);
  }

  Future<void> softDeleteCategory(String id) async {
    await (_db.update(_db.expenseCategories)..where((c) => c.id.equals(id))).write(
      ExpenseCategoriesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Fetches a single expense with its joined details.
  Future<ExpenseWithDetails?> getExpenseById(String id) async {
    final query = _db.select(_db.expenses).join([
      innerJoin(
        _db.expenseCategories,
        _db.expenseCategories.id.equalsExp(_db.expenses.categoryId),
      ),
      innerJoin(
        _db.vehicles,
        _db.vehicles.id.equalsExp(_db.expenses.vehicleId),
      ),
    ]);

    query.where(_db.expenses.id.equals(id) & _db.expenses.deletedAt.isNull());

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return ExpenseWithDetails(
      expense: row.readTable(_db.expenses),
      category: row.readTable(_db.expenseCategories),
      vehicle: row.readTable(_db.vehicles),
    );
  }

  /// Saves or updates an expense record, encrypting receipt photo if provided.
  Future<String> saveExpense({
    String? id,
    required String vehicleId,
    required String categoryId,
    required DateTime date,
    required double amount,
    double? odometer,
    String? notes,
    Uint8List? receiptBytes,
    String? receiptFileName,
  }) async {
    final expenseId = id ?? _uuid.v4();
    final now = DateTime.now();

    String? receiptPath;
    if (receiptBytes != null && receiptBytes.isNotEmpty) {
      final ext = (receiptFileName != null && receiptFileName.contains('.'))
          ? '.${receiptFileName.split('.').last}'
          : '.jpg';

      receiptPath = await _cryptoService.saveEncryptedFile(
        rawBytes: receiptBytes,
        fileExtension: ext,
      );
    }

    final existing = await (_db.select(_db.expenses)
          ..where((e) => e.id.equals(expenseId)))
        .getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.expenses).insert(
            ExpensesCompanion.insert(
              id: expenseId,
              vehicleId: vehicleId,
              categoryId: categoryId,
              date: date,
              amount: amount,
              odometer: Value(odometer),
              notes: Value(notes),
              receiptPath: Value(receiptPath),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    } else {
      await (_db.update(_db.expenses)..where((e) => e.id.equals(expenseId))).write(
        ExpensesCompanion(
          vehicleId: Value(vehicleId),
          categoryId: Value(categoryId),
          date: Value(date),
          amount: Value(amount),
          odometer: Value(odometer),
          notes: Value(notes),
          receiptPath: receiptPath != null ? Value(receiptPath) : const Value.absent(),
          updatedAt: Value(now),
          deletedAt: const Value(null),
        ),
      );
    }

    return expenseId;
  }

  /// Soft deletes an expense.
  Future<void> softDeleteExpense(String id) async {
    final now = DateTime.now();
    await (_db.update(_db.expenses)..where((e) => e.id.equals(id))).write(
      ExpensesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// Creates a custom expense category.
  Future<String> createCustomCategory({
    required String name,
    String? icon,
  }) async {
    final catId = _uuid.v4();
    final now = DateTime.now();
    final code = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

    await _db.into(_db.expenseCategories).insert(
          ExpenseCategoriesCompanion.insert(
            id: catId,
            name: name,
            code: Value(code),
            icon: Value(icon),
            isCustom: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    return catId;
  }

  /// Streams total cost of other expenses for a given vehicle in the current month.
  Stream<double> watchTotalExpensesThisMonth(String? vehicleId) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return watchExpenses(
      vehicleId: vehicleId,
      startDate: startOfMonth,
      endDate: endOfMonth,
    ).map((expenses) {
      return expenses.fold<double>(0.0, (sum, e) => sum + e.expense.amount);
    });
  }

  /// Decrypts an encrypted receipt file for viewing.
  Future<Uint8List> decryptReceipt(String relativePath) {
    return _cryptoService.readEncryptedFile(relativePath);
  }
}
