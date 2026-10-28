import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_and_service_log/core/database/app_database.dart';
import 'package:fuel_and_service_log/core/localization/generated/app_localizations.dart';
import 'package:fuel_and_service_log/core/providers/database_provider.dart';
import 'package:fuel_and_service_log/features/settings/presentation/settings_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('SettingsScreen renders all configuration sections and handles interactions', (tester) async {
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
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Settings'), findsOneWidget);

    // Appearance & Language
    expect(find.text('Appearance & Language'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);

    // Units
    expect(find.text('Units & Measurement'), findsOneWidget);
    expect(find.text('Currency'), findsOneWidget);
    expect(find.text('Distance Unit'), findsOneWidget);
    expect(find.text('Volume Unit'), findsOneWidget);

    // Notifications
    expect(find.text('Notifications & Alerts'), findsOneWidget);
    expect(find.text('Service Reminders'), findsOneWidget);
    expect(find.text('Document Expiry Alerts'), findsOneWidget);

    // Vault Security
    expect(find.text('Vault Security'), findsOneWidget);
    expect(find.text('Document Vault Lock & PIN'), findsOneWidget);

    // Custom Types Management
    expect(find.text('Manage Custom Categories'), findsOneWidget);
    expect(find.text('Service Types'), findsOneWidget);
    expect(find.text('Expense Categories'), findsOneWidget);
    expect(find.text('Document Types'), findsOneWidget);

    // Tap Currency tile to open dialog
    await tester.tap(find.text('Currency'));
    await tester.pumpAndSettle();

    expect(find.text('Select Currency'), findsOneWidget);
    expect(find.text('US Dollar (\$)'), findsOneWidget);

    // Close currency dialog
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    // Clean unmount
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}

