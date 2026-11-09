import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocents/core/database/app_database.dart';
import 'package:motocents/core/notifications/notification_service.dart';
import 'package:motocents/features/documents/data/documents_repository.dart';
import 'package:motocents/features/documents/domain/document_expiry_calculator.dart';
import 'package:motocents/features/documents/domain/vault_crypto_service.dart';

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

class FakeNotificationService extends Fake implements NotificationService {
  final List<({int id, String title, String body, DateTime date})> scheduled = [];
  final List<int> cancelled = [];

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    scheduled.add((id: id, title: title, body: body, date: scheduledDate));
  }

  @override
  Future<void> cancelNotification(int id) async {
    cancelled.add(id);
  }
}

void main() {
  late Directory tempDir;
  late AppDatabase testDb;
  late MockSecureStorage mockStorage;
  late VaultCryptoService cryptoService;
  late FakeNotificationService fakeNotifService;
  late DocumentsRepository repo;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = Directory.systemTemp.createTempSync('vault_test_');
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
    await testDb.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('DocumentsRepository Integration Tests', () {
    test('Save, query, toggle Quick Show, and soft-delete a document', () async {
      // 1. Fetch available document types
      final docTypes = await repo.watchDocumentTypes().first;
      expect(docTypes, isNotEmpty);
      final dlType = docTypes.firstWhere((t) => t.code == 'driving_license');

      // 2. Save a driver-level document (no vehicle)
      final dummyBytes = Uint8List.fromList(utf8.encode('DRIVING_LICENSE_SAMPLE_IMAGE'));
      final docId = await repo.saveDocument(
        documentTypeId: dlType.id,
        title: 'My Driving License',
        documentNumber: 'DL-2024-998811',
        issuingAuthority: 'BRTA',
        issueDate: DateTime(2022, 1, 15),
        expiryDate: DateTime.now().add(const Duration(days: 45)),
        isQuickShow: true,
        reminderDaysBefore: '30,15,7,1',
        newAttachments: [
          DocumentFileAttachment(
            rawBytes: dummyBytes,
            fileName: 'license_front.jpg',
            mimeType: 'image/jpeg',
            pageNumber: 1,
          ),
        ],
      );

      expect(docId, isNotEmpty);

      // 3. Query documents
      final docs = await repo.watchDocuments().first;
      expect(docs.length, equals(1));
      final savedDoc = docs.first;
      expect(savedDoc.document.title, equals('My Driving License'));
      expect(savedDoc.document.documentNumber, equals('DL-2024-998811'));
      expect(savedDoc.document.isQuickShow, isTrue);
      expect(savedDoc.files.length, equals(1));
      expect(savedDoc.expiryStatus, equals(DocumentExpiryStatus.valid));

      // 4. Verify file was saved and can be decrypted back to identical bytes
      final decryptedBytes = await repo.decryptFile(savedDoc.files.first.filePath);
      expect(utf8.decode(decryptedBytes), equals('DRIVING_LICENSE_SAMPLE_IMAGE'));

      // 5. Toggle Quick Show
      await repo.toggleQuickShow(docId, false);
      final updatedDocs = await repo.watchDocuments().first;
      expect(updatedDocs.first.document.isQuickShow, isFalse);

      // 6. Soft Delete
      await repo.softDeleteDocument(docId);
      final emptyDocs = await repo.watchDocuments().first;
      expect(emptyDocs, isEmpty);

      // Verify notifications were cancelled upon deletion
      expect(fakeNotifService.cancelled, isNotEmpty);
    });

    test('Expiring count reflects documents within 30 days and expired', () async {
      final docTypes = await repo.watchDocumentTypes().first;
      final regType = docTypes.firstWhere((t) => t.code == 'registration');

      // Add a document expiring in 10 days
      await repo.saveDocument(
        documentTypeId: regType.id,
        title: 'Vehicle Registration',
        expiryDate: DateTime.now().add(const Duration(days: 10)),
      );

      final count = await repo.watchExpiringCount().first;
      expect(count, equals(1));
    });
  });
}
