import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_and_service_log/core/database/app_database.dart';
import 'package:fuel_and_service_log/core/localization/generated/app_localizations.dart';
import 'package:fuel_and_service_log/core/providers/database_provider.dart';
import 'package:fuel_and_service_log/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('OnboardingScreen renders slides, handles Next navigation and Skip', (tester) async {
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
          home: OnboardingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Slide 1
    expect(find.text('PRECISION FUEL LOG'), findsOneWidget);
    expect(find.text('Smart Fuel & Mileage Tracking'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Tap Next -> Slide 2
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('MAINTENANCE & VAULT'), findsOneWidget);
    expect(find.text('Service Alerts & Document Vault'), findsOneWidget);

    // Tap Next -> Slide 3
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('ZERO CLOUD • 100% PRIVATE'), findsOneWidget);
    expect(find.text('100% Offline & Private'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    // Clean unmount
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
