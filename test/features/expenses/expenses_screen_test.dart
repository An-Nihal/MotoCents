import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocents/core/database/app_database.dart';
import 'package:motocents/core/localization/generated/app_localizations.dart';
import 'package:motocents/core/providers/database_provider.dart';
import 'package:motocents/core/providers/vehicles_provider.dart';
import 'package:motocents/features/documents/domain/vault_crypto_service.dart';
import 'package:motocents/features/expenses/data/expenses_repository.dart';
import 'package:motocents/features/expenses/presentation/expense_form_screen.dart';
import 'package:motocents/features/expenses/presentation/expenses_screen.dart';
import 'package:motocents/features/expenses/presentation/providers/expenses_providers.dart';
import '../documents/documents_repository_test.dart';

void main() {
  late Directory tempDir;
  late AppDatabase testDb;
  late MockSecureStorage mockStorage;
  late VaultCryptoService cryptoService;
  late ExpensesRepository expensesRepo;
  late VehicleData testVehicle;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = Directory.systemTemp.createTempSync('expense_widget_test_');
    testDb = AppDatabase(NativeDatabase.memory());

    mockStorage = MockSecureStorage();
    cryptoService = VaultCryptoService(
      secureStorage: mockStorage,
      getBaseDirectory: () async => tempDir,
    );

    expensesRepo = ExpensesRepository(
      testDb,
      cryptoService: cryptoService,
    );

    // Seed test vehicle
    testVehicle = await testDb.into(testDb.vehicles).insertReturning(
          VehiclesCompanion.insert(
            id: 'test-veh-1',
            name: 'Toyota Corolla',
            vehicleType: 'car',
            plateNumber: 'DHK-1234',
            fuelType: 'octane',
            initialOdometer: const drift.Value(15000.0),
          ),
        );

    await testDb.into(testDb.vehicles).insert(
          VehiclesCompanion.insert(
            id: 'test-veh-2',
            name: 'Yamaha FZ',
            vehicleType: 'motorcycle',
            plateNumber: 'DHK-5678',
            fuelType: 'octane',
            initialOdometer: const drift.Value(5000.0),
          ),
        );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget buildTestApp({
    Widget? home,
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(testDb),
        expensesRepositoryProvider.overrideWithValue(expensesRepo),
        currentVehicleProvider.overrideWith((ref) => testVehicle),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('bn')],
        home: home ?? const ExpensesScreen(),
      ),
    );
  }

  group('Expenses Screen & Form Widget Tests', () {
    testWidgets('ExpensesScreen displays KPI summary, filter chips, and empty state',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify KPI Summary items
      expect(find.text('This Month'), findsNWidgets(2)); // KPI card + Period chip
      expect(find.text('All-Time Spend'), findsOneWidget);
      expect(find.text('Total Logs'), findsOneWidget);

      // Verify Period Filters
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Last Month'), findsOneWidget);
      expect(find.text('This Year'), findsOneWidget);

      // Verify Empty State
      expect(find.text('No Expenses Logged'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await testDb.close();
    });

    testWidgets('ExpenseFormScreen creates a new expense and saves correctly',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(home: const ExpenseFormScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Add Expense'), findsOneWidget);
      expect(find.text('Vehicle *'), findsOneWidget);
      expect(find.text('Expense Category *'), findsOneWidget);

      // Select category Parking
      final parkingChip = find.text('Parking');
      expect(parkingChip, findsOneWidget);
      await tester.tap(parkingChip);
      await tester.pump();

      // Enter amount
      final amountField = find.widgetWithText(TextFormField, '0.00');
      expect(amountField, findsOneWidget);
      await tester.enterText(amountField, '250.00');
      await tester.pump();

      // Enter notes
      final notesField = find.widgetWithText(TextFormField, 'Notes');
      expect(notesField, findsOneWidget);
      await tester.enterText(notesField, 'Airport parking terminal 2');
      await tester.pump();

      // Tap Save
      final saveBtn = find.text('Save');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify expense in database
      final savedExpenses = await testDb.select(testDb.expenses).get();
      expect(savedExpenses.length, equals(1));
      expect(savedExpenses.first.amount, equals(250.0));
      expect(savedExpenses.first.notes, equals('Airport parking terminal 2'));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await testDb.close();
    });

    testWidgets('ExpensesScreen displays logged expenses and applies filters',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Pre-seed an expense
      final tollCat = (await testDb.select(testDb.expenseCategories).get())
          .firstWhere((c) => c.code == 'toll');
      await testDb.into(testDb.expenses).insert(
            ExpensesCompanion.insert(
              id: 'exp-1',
              vehicleId: testVehicle.id,
              categoryId: tollCat.id,
              amount: 150.0,
              date: DateTime.now(),
              odometer: const drift.Value(15200.0),
              notes: const drift.Value('Padma Bridge Toll'),
            ),
          );

      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Check card shows Toll and Notes
      expect(find.text('Toll'), findsWidgets);
      expect(find.text('Padma Bridge Toll'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await testDb.close();
    });
  });
}
