import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';
import '../domain/document_expiry_calculator.dart';
import '../domain/vault_crypto_service.dart';

const _uuid = Uuid();

class DocumentFileAttachment {
  final Uint8List rawBytes;
  final String fileName;
  final String mimeType;
  final int pageNumber;

  const DocumentFileAttachment({
    required this.rawBytes,
    required this.fileName,
    required this.mimeType,
    this.pageNumber = 1,
  });
}

class DocumentWithDetails {
  final DocumentData document;
  final DocumentTypeData documentType;
  final VehicleData? vehicle;
  final List<DocumentFileData> files;

  const DocumentWithDetails({
    required this.document,
    required this.documentType,
    required this.vehicle,
    required this.files,
  });

  bool get isVehicleSpecific => document.vehicleId != null;

  DocumentExpiryStatus get expiryStatus =>
      DocumentExpiryCalculator.calculateStatus(expiryDate: document.expiryDate);

  int? get daysUntilExpiry =>
      DocumentExpiryCalculator.getDaysUntilExpiry(expiryDate: document.expiryDate);

  String get formattedExpiryStatus => DocumentExpiryCalculator.formatStatusLabel(
        status: expiryStatus,
        daysRemaining: daysUntilExpiry,
      );
}

class DocumentsRepository {
  final AppDatabase _db;
  final VaultCryptoService _cryptoService;
  final NotificationService _notificationService;

  DocumentsRepository(
    this._db, {
    VaultCryptoService? cryptoService,
    NotificationService? notificationService,
  })  : _cryptoService = cryptoService ?? VaultCryptoService(),
        _notificationService = notificationService ?? NotificationService();

  /// Watches all non-deleted documents, optionally filtered by vehicleId or quickShowOnly.
  Stream<List<DocumentWithDetails>> watchDocuments({
    String? vehicleId,
    bool? quickShowOnly,
    bool includeDriverDocs = true,
  }) {
    final query = _db.select(_db.documents).join([
      innerJoin(
        _db.documentTypes,
        _db.documentTypes.id.equalsExp(_db.documents.documentTypeId),
      ),
      leftOuterJoin(
        _db.vehicles,
        _db.vehicles.id.equalsExp(_db.documents.vehicleId),
      ),
    ]);

    query.where(_db.documents.deletedAt.isNull());

    if (quickShowOnly == true) {
      query.where(_db.documents.isQuickShow.equals(true));
    }

    if (vehicleId != null && vehicleId.isNotEmpty) {
      if (includeDriverDocs) {
        // Vehicle documents matching vehicleId OR Driver documents (vehicleId is null)
        query.where(
          _db.documents.vehicleId.equals(vehicleId) |
              _db.documents.vehicleId.isNull(),
        );
      } else {
        query.where(_db.documents.vehicleId.equals(vehicleId));
      }
    }

    query.orderBy([
      OrderingTerm(expression: _db.documents.isQuickShow, mode: OrderingMode.desc),
      OrderingTerm(expression: _db.documents.expiryDate, mode: OrderingMode.asc),
      OrderingTerm(expression: _db.documents.createdAt, mode: OrderingMode.desc),
    ]);

    return query.watch().asyncMap((rows) async {
      final docIds = rows.map((r) => r.readTable(_db.documents).id).toList();

      // Fetch all attached files for these documents in batch
      final files = docIds.isEmpty
          ? <DocumentFileData>[]
          : await (_db.select(_db.documentFiles)
                ..where((f) => f.documentId.isIn(docIds) & f.deletedAt.isNull())
                ..orderBy([(f) => OrderingTerm.asc(f.pageNumber)]))
              .get();

      final filesByDocId = <String, List<DocumentFileData>>{};
      for (final f in files) {
        filesByDocId.putIfAbsent(f.documentId, () => []).add(f);
      }

      return rows.map((row) {
        final doc = row.readTable(_db.documents);
        final docType = row.readTable(_db.documentTypes);
        final vehicle = row.readTableOrNull(_db.vehicles);
        final docFiles = filesByDocId[doc.id] ?? <DocumentFileData>[];

        return DocumentWithDetails(
          document: doc,
          documentType: docType,
          vehicle: vehicle,
          files: docFiles,
        );
      }).toList();
    });
  }

  /// Watches all document types (pre-seeded + custom).
  Stream<List<DocumentTypeData>> watchDocumentTypes() {
    return (_db.select(_db.documentTypes)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<void> createDocumentType(DocumentTypesCompanion companion) async {
    await _db.into(_db.documentTypes).insert(companion);
  }

  Future<void> softDeleteDocumentType(String id) async {
    await (_db.update(_db.documentTypes)..where((t) => t.id.equals(id))).write(
      DocumentTypesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Fetches a single document with all files and joined metadata.
  Future<DocumentWithDetails?> getDocumentById(String id) async {
    final query = _db.select(_db.documents).join([
      innerJoin(
        _db.documentTypes,
        _db.documentTypes.id.equalsExp(_db.documents.documentTypeId),
      ),
      leftOuterJoin(
        _db.vehicles,
        _db.vehicles.id.equalsExp(_db.documents.vehicleId),
      ),
    ]);

    query.where(_db.documents.id.equals(id) & _db.documents.deletedAt.isNull());

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final doc = row.readTable(_db.documents);
    final docType = row.readTable(_db.documentTypes);
    final vehicle = row.readTableOrNull(_db.vehicles);

    final files = await (_db.select(_db.documentFiles)
          ..where((f) => f.documentId.equals(id) & f.deletedAt.isNull())
          ..orderBy([(f) => OrderingTerm.asc(f.pageNumber)]))
        .get();

    return DocumentWithDetails(
      document: doc,
      documentType: docType,
      vehicle: vehicle,
      files: files,
    );
  }

  /// Saves or updates a document and encrypts any new attached files on disk.
  Future<String> saveDocument({
    String? id,
    String? vehicleId,
    required String documentTypeId,
    required String title,
    String? documentNumber,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? issuingAuthority,
    String? notes,
    bool isQuickShow = false,
    String reminderDaysBefore = '30,15,7,1',
    List<DocumentFileAttachment> newAttachments = const [],
    List<String> fileIdsToDelete = const [],
  }) async {
    final docId = id ?? _uuid.v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      // 1. Upsert document record
      final existing = await (_db.select(_db.documents)
            ..where((d) => d.id.equals(docId)))
          .getSingleOrNull();

      if (existing == null) {
        await _db.into(_db.documents).insert(
              DocumentsCompanion.insert(
                id: docId,
                vehicleId: Value(vehicleId),
                documentTypeId: documentTypeId,
                title: title,
                documentNumber: Value(documentNumber),
                issueDate: Value(issueDate),
                expiryDate: Value(expiryDate),
                issuingAuthority: Value(issuingAuthority),
                notes: Value(notes),
                isQuickShow: Value(isQuickShow),
                reminderDaysBefore: Value(reminderDaysBefore),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
      } else {
        await (_db.update(_db.documents)..where((d) => d.id.equals(docId))).write(
          DocumentsCompanion(
            vehicleId: Value(vehicleId),
            documentTypeId: Value(documentTypeId),
            title: Value(title),
            documentNumber: Value(documentNumber),
            issueDate: Value(issueDate),
            expiryDate: Value(expiryDate),
            issuingAuthority: Value(issuingAuthority),
            notes: Value(notes),
            isQuickShow: Value(isQuickShow),
            reminderDaysBefore: Value(reminderDaysBefore),
            updatedAt: Value(now),
            deletedAt: const Value(null),
          ),
        );
      }

      // 2. Soft-delete requested files
      if (fileIdsToDelete.isNotEmpty) {
        await (_db.update(_db.documentFiles)
              ..where((f) => f.id.isIn(fileIdsToDelete)))
            .write(
          DocumentFilesCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }

      // 3. Encrypt and save new attachments
      for (final attachment in newAttachments) {
        final extension = attachment.fileName.contains('.')
            ? '.${attachment.fileName.split('.').last}'
            : '.jpg';

        final relativePath = await _cryptoService.saveEncryptedFile(
          rawBytes: attachment.rawBytes,
          fileExtension: extension,
        );

        final fileId = _uuid.v4();
        await _db.into(_db.documentFiles).insert(
              DocumentFilesCompanion.insert(
                id: fileId,
                documentId: docId,
                filePath: relativePath,
                fileName: attachment.fileName,
                mimeType: attachment.mimeType,
                pageNumber: Value(attachment.pageNumber),
                fileSizeBytes: Value(attachment.rawBytes.length),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
      }
    });

    // 4. Update scheduled notifications
    await _rescheduleNotifications(
      docId: docId,
      title: title,
      expiryDate: expiryDate,
      reminderDaysBefore: reminderDaysBefore,
    );

    return docId;
  }

  /// Toggles quick show status.
  Future<void> toggleQuickShow(String id, bool isQuickShow) async {
    await (_db.update(_db.documents)..where((d) => d.id.equals(id))).write(
      DocumentsCompanion(
        isQuickShow: Value(isQuickShow),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Soft deletes a document and cancels its notifications.
  Future<void> softDeleteDocument(String id) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(_db.documents)..where((d) => d.id.equals(id))).write(
        DocumentsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await (_db.update(_db.documentFiles)..where((f) => f.documentId.equals(id)))
          .write(
        DocumentFilesCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });

    await _cancelNotifications(id);
  }

  /// Decrypts an encrypted document file for viewing.
  Future<Uint8List> decryptFile(String relativePath) {
    return _cryptoService.readEncryptedFile(relativePath);
  }

  /// Stream of count of documents expiring soon or expired.
  Stream<int> watchExpiringCount({
    String? vehicleId,
    int warningDays = 30,
  }) {
    return watchDocuments(vehicleId: vehicleId).map((docs) {
      return docs.where((d) {
        final status = d.expiryStatus;
        return status == DocumentExpiryStatus.expiringSoon ||
            status == DocumentExpiryStatus.expired;
      }).length;
    });
  }

  Future<void> _rescheduleNotifications({
    required String docId,
    required String title,
    required DateTime? expiryDate,
    required String reminderDaysBefore,
  }) async {
    await _cancelNotifications(docId);

    if (expiryDate == null) return;

    final daysList = DocumentExpiryCalculator.parseReminderDays(reminderDaysBefore);
    final schedule = DocumentExpiryCalculator.getNotificationSchedule(
      expiryDate: expiryDate,
      reminderDays: daysList,
    );

    for (final item in schedule) {
      final notifId = _generateNotificationId(docId, item.daysBefore);
      final body = item.daysBefore == 1
          ? '$title expires tomorrow!'
          : '$title expires in ${item.daysBefore} days.';

      await _notificationService.scheduleNotification(
        id: notifId,
        title: 'Document Expiring: $title',
        body: body,
        scheduledDate: item.scheduledDate,
      );
    }
  }

  Future<void> _cancelNotifications(String docId) async {
    // Standard days: 30, 15, 7, 1
    for (final d in [60, 30, 15, 7, 1]) {
      final notifId = _generateNotificationId(docId, d);
      await _notificationService.cancelNotification(notifId);
    }
  }

  int _generateNotificationId(String docId, int daysBefore) {
    // Deterministic 31-bit positive int id
    return (docId.hashCode ^ daysBefore.hashCode).abs() & 0x7FFFFFFF;
  }
}
