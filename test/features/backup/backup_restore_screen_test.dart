import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocents/core/database/app_database.dart';
import 'package:motocents/core/localization/generated/app_localizations.dart';
import 'package:motocents/core/providers/database_provider.dart';
import 'package:motocents/features/backup/presentation/backup_restore_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('BackupRestoreScreen renders status, create, restore, and security cards', (tester) async {
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
          home: BackupRestoreScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Backup & Restore'), findsOneWidget);

    // Verify Status Card
    expect(find.text('Last Encrypted Backup'), findsOneWidget);
    expect(find.text('30-Day Backup Reminder'), findsOneWidget);

    // Verify Create Backup Card
    expect(find.text('Create Encrypted Backup'), findsOneWidget);
    expect(find.text('Create & Share Backup (.fslbackup)'), findsOneWidget);

    // Verify Restore Backup Card
    expect(find.text('Restore from Backup'), findsOneWidget);
    expect(find.text('Select File & Restore'), findsOneWidget);

    // Verify Privacy Guarantee Note
    expect(find.text('100% Offline & Private'), findsOneWidget);

    // Clean unmount
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
