import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_and_service_log/core/database/app_database.dart';
import 'package:fuel_and_service_log/features/documents/domain/vault_crypto_service.dart';
import 'package:fuel_and_service_log/features/expenses/data/expenses_repository.dart';

class MockSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    } else {
      _storage.remove(key);
    }
  }
}

void main() {
  late Directory tempDir;
  late AppDatabase testDb;
  late MockSecureStorage mockStorage;
  late VaultCryptoService cryptoService;
  late ExpensesRepository repo;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = Directory.systemTemp.createTempSync('expense_test_');
    testDb = AppDatabase(NativeDatabase.memory());

    // Insert a parent vehicle for foreign key
    await testDb.into(testDb.vehicles).insert(
          VehiclesCompanion.insert(
            id: 'v-test-1',
            name: 'Test Car',
            vehicleType: 'car',
            plateNumber: 'DHK-0011',
            fuelType: 'octane',
          ),
        );

    mockStorage = MockSecureStorage();
    cryptoService = VaultCryptoService(
      secureStorage: mockStorage,
      getBaseDirectory: () async => tempDir,
    );

    repo = ExpensesRepository(testDb, cryptoService: cryptoService);
  });

  tearDown(() async {
    await testDb.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ExpensesRepository Tests', () {
    test('Create category, save expense with receipt, retrieve, and soft delete', () async {
      // 1. Verify default categories exist
      final categories = await repo.watchCategories().first;
      expect(categories, isNotEmpty);
      final parkingCat = categories.firstWhere((c) => c.code == 'parking');

      // 2. Save an expense with encrypted receipt
      final receiptBytes = Uint8List.fromList(utf8.encode('SAMPLE_RECEIPT_IMAGE_DATA'));
      final expenseId = await repo.saveExpense(
        vehicleId: 'v-test-1',
        categoryId: parkingCat.id,
        date: DateTime(2026, 10, 15, 14, 30),
        amount: 250.0,
        odometer: 12050.0,
        notes: 'Airport parking',
        receiptBytes: receiptBytes,
        receiptFileName: 'parking_slip.jpg',
      );

      expect(expenseId, isNotEmpty);

      // 3. Query expense list
      final expenses = await repo.watchExpenses(vehicleId: 'v-test-1').first;
      expect(expenses.length, equals(1));
      final saved = expenses.first;
      expect(saved.expense.amount, equals(250.0));
      expect(saved.category.name, equals('Parking'));
      expect(saved.vehicle.name, equals('Test Car'));
      expect(saved.expense.receiptPath, isNotNull);

      // 4. Decrypt receipt and verify bytes
      final decrypted = await repo.decryptReceipt(saved.expense.receiptPath!);
      expect(utf8.decode(decrypted), equals('SAMPLE_RECEIPT_IMAGE_DATA'));

      // 5. Query single expense
      final single = await repo.getExpenseById(expenseId);
      expect(single, isNotNull);
      expect(single!.expense.notes, equals('Airport parking'));

      // 6. Soft delete
      await repo.softDeleteExpense(expenseId);
      final emptyList = await repo.watchExpenses(vehicleId: 'v-test-1').first;
      expect(emptyList, isEmpty);
    });

    test('Create custom category', () async {
      final catId = await repo.createCustomCategory(
        name: 'Car Detailing',
        icon: 'clean_hands',
      );

      final categories = await repo.watchCategories().first;
      expect(categories.any((c) => c.id == catId && c.name == 'Car Detailing'), isTrue);
    });
  });
}
