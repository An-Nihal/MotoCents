import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocents/core/database/app_database.dart';
import 'package:motocents/core/localization/generated/app_localizations.dart';
import 'package:motocents/core/providers/database_provider.dart';
import 'package:motocents/features/reports/presentation/reports_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());

    // Insert mock vehicle
    await db.into(db.vehicles).insert(
          VehiclesCompanion.insert(
            id: 'v-101',
            name: 'Honda Civic',
            vehicleType: 'car',
            fuelType: 'octane',
            plateNumber: 'DHK-9999',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('ReportsScreen renders vehicle selector, PDF, export and import sections', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ReportsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Reports & Data'), findsOneWidget);

    // Verify Vehicle History PDF Section
    expect(find.text('Vehicle History Report'), findsOneWidget);
    expect(find.text('View / Print'), findsOneWidget);
    expect(find.text('Share PDF'), findsOneWidget);

    // Verify Spreadsheet Export Section
    expect(find.text('Spreadsheet Export'), findsOneWidget);
    expect(find.text('Export Complete Excel Workbook (.xlsx)'), findsOneWidget);
    expect(find.text('Fuel Logs (CSV)'), findsOneWidget);

    // Verify Import Section
    expect(find.text('Import Data'), findsOneWidget);
    expect(find.text('Import Fuel Logs from CSV'), findsOneWidget);

    // Clean unmount
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
