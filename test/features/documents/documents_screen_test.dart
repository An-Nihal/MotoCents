import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocents/core/database/app_database.dart';
import 'package:motocents/core/localization/generated/app_localizations.dart';
import 'package:motocents/core/providers/database_provider.dart';
import 'package:motocents/features/documents/data/documents_repository.dart';
import 'package:motocents/features/documents/domain/vault_crypto_service.dart';
import 'package:motocents/features/documents/presentation/document_form_screen.dart';
import 'package:motocents/features/documents/presentation/documents_screen.dart';
import 'package:motocents/features/documents/presentation/providers/documents_providers.dart';
import 'package:motocents/features/documents/presentation/quick_show_screen.dart';
import 'package:motocents/features/documents/presentation/vault_lock_view.dart';
import 'documents_repository_test.dart';

class FakeUnlockedVaultNotifier extends VaultLockNotifier {
  final bool initialUnlocked;
  FakeUnlockedVaultNotifier({this.initialUnlocked = true});

  @override
  Future<bool> build() async => initialUnlocked;
}

void main() {
  late Directory tempDir;
  late AppDatabase testDb;
  late MockSecureStorage mockStorage;
  late VaultCryptoService cryptoService;
  late FakeNotificationService fakeNotifService;
  late DocumentsRepository repo;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = Directory.systemTemp.createTempSync('vault_widget_test_');
    testDb = AppDatabase(NativeDatabase.memory());

    mockStorage = MockSecureStorage();
    cryptoService = VaultCryptoService(
      secureStorage: mockStorage,
      getBaseDirectory: () async => tempDir,
    );
    fakeNotifService = FakeNotificationService();

    repo = DocumentsRepository(
      testDb,
      cryptoService: cryptoService,
      notificationService: fakeNotifService,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget buildTestApp({
    Widget? home,
    bool vaultUnlocked = true,
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(testDb),
        vaultCryptoServiceProvider.overrideWithValue(cryptoService),
        documentsRepositoryProvider.overrideWithValue(repo),
        vaultLockNotifierProvider.overrideWith(
          () => FakeUnlockedVaultNotifier(initialUnlocked: vaultUnlocked),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('bn')],
        home: home ?? const DocumentsScreen(),
      ),
    );
  }

  group('Document Vault Widget Tests', () {
    testWidgets('DocumentsScreen renders KPI strip and empty state when unlocked',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Expiring'), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget);
      expect(find.text('Quick Show'), findsNWidgets(2)); // KPI card + filter chip
      expect(find.text('No Documents in Vault'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await testDb.close();
    });

    testWidgets('DocumentFormScreen fills fields and saves document',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(home: const DocumentFormScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Check fields
      expect(find.text('Add Document'), findsOneWidget);
      expect(find.text('Document Type *'), findsOneWidget);
      expect(find.text('Document Title *'), findsOneWidget);
      expect(find.text('Traffic Police Quick Show'), findsOneWidget);

      // Enter document number
      final docNumField = find.widgetWithText(TextFormField, 'Document Number');
      expect(docNumField, findsOneWidget);
      await tester.enterText(docNumField, 'DL-990011');

      // Tap Save
      final saveBtn = find.text('Save');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify saved in repository
      final docs = await repo.watchDocuments().first;
      expect(docs.length, equals(1));
      expect(docs.first.document.documentNumber, equals('DL-990011'));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await testDb.close();
    });

    testWidgets('VaultLockView renders keypad and police check bypass button',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestApp(
          home: const Scaffold(body: VaultLockView()),
          vaultUnlocked: false,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Document Vault Locked'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Open Quick Show (Police Check)'), findsOneWidget);

      // Tap Open Quick Show
      await tester.tap(find.text('Open Quick Show (Police Check)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifies navigation to QuickShowScreen
      expect(find.byType(QuickShowScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await testDb.close();
    });
  });
}
