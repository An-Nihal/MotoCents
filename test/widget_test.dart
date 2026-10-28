import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_and_service_log/core/database/app_database.dart';
import 'package:fuel_and_service_log/core/providers/database_provider.dart';
import 'package:fuel_and_service_log/main.dart';

void main() {
  testWidgets('App launches with bottom navigation and home dashboard',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final testDb = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const FuelAndServiceLogApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify navigation bar exists
    expect(find.byType(NavigationBar), findsOneWidget);
    // Home tab is initially selected
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.local_gas_station_outlined), findsOneWidget);
    expect(find.byIcon(Icons.build_outlined), findsOneWidget);
    expect(find.byIcon(Icons.folder_shared_outlined), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_outlined), findsOneWidget);

    // Verify FAB on home
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Tap Fuel tab using destination item
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // In Fuel tab, FAB should be hidden
    expect(find.byType(FloatingActionButton), findsNothing);

    // Switch to More tab (index 4)
    await tester.tap(find.byType(NavigationDestination).at(4));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Features'), findsOneWidget);
    expect(find.text('Settings'), findsAtLeastNWidgets(1));

    // Unmount widget tree to close active subscriptions cleanly
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    await testDb.close();
  });
}
