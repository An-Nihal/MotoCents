import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/database/app_database.dart';
import '../domain/backup_manifest.dart';
import 'backup_crypto_service.dart';

class BackupService {
  final AppDatabase db;
  final BackupCryptoService _cryptoService;
  final Future<Directory> Function() _getBaseDirectory;

  BackupService({
    required this.db,
    BackupCryptoService? cryptoService,
    Future<Directory> Function()? getBaseDirectory,
  })  : _cryptoService = cryptoService ?? BackupCryptoService(),
        _getBaseDirectory = getBaseDirectory ?? getApplicationDocumentsDirectory;

  /// Creates a password-encrypted `.fslbackup` file containing the full SQLite database,
  /// document vault files, and manifest metadata.
  Future<File> createBackup({required String password}) async {
    final baseDir = await _getBaseDirectory();
    final now = DateTime.now();

    // 1. Gather counts for manifest
    final vehicles = await db.select(db.vehicles).get();
    final fuelEntries = await db.select(db.fuelEntries).get();
    final serviceEntries = await db.select(db.serviceEntries).get();
    final expenses = await db.select(db.expenses).get();
    final documents = await db.select(db.documents).get();

    final manifest = BackupManifest(
      createdAt: now,
      vehicleCount: vehicles.length,
      fuelEntryCount: fuelEntries.length,
      serviceEntryCount: serviceEntries.length,
      expenseCount: expenses.length,
      documentCount: documents.length,
    );

    // 2. Build in-memory archive
    final archive = Archive();

    // Add manifest
    final manifestBytes = utf8.encode(manifest.toJson());
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

    // Add SQLite database file if it exists on disk
    final dbFile = File(p.join(baseDir.path, 'fuel_service_log.sqlite'));
    if (await dbFile.exists()) {
      final dbBytes = await dbFile.readAsBytes();
      archive.addFile(ArchiveFile('fuel_service_log.sqlite', dbBytes.length, dbBytes));
    }

    // Add all vault files
    final vaultDir = Directory(p.join(baseDir.path, 'vault'));
    if (await vaultDir.exists()) {
      final vaultFiles = await vaultDir.list(recursive: true).toList();
      for (final entity in vaultFiles) {
        if (entity is File) {
          final relPath = p.relative(entity.path, from: baseDir.path).replaceAll(r'\', '/');
          final fileBytes = await entity.readAsBytes();
          archive.addFile(ArchiveFile(relPath, fileBytes.length, fileBytes));
        }
      }
    }

    // 3. Compress into zip archive
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);
    if (zipBytes == null) {
      throw Exception('Failed to compress backup files');
    }

    // 4. Authenticated encryption (PBKDF2 + AES-256-GCM)
    final encryptedBytes = await _cryptoService.encryptArchive(
      rawBytes: Uint8List.fromList(zipBytes),
      password: password,
    );

    // 5. Write to temporary export path
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final fileName = 'fsl_backup_$timestamp.fslbackup';
    final exportDir = Directory(p.join(baseDir.path, 'backups'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final backupFile = File(p.join(exportDir.path, fileName));
    await backupFile.writeAsBytes(encryptedBytes, flush: true);

    return backupFile;
  }

  /// Restores database and vault files from an encrypted `.fslbackup` file after password verification.
  Future<BackupManifest> restoreBackup({
    required File backupFile,
    required String password,
  }) async {
    final baseDir = await _getBaseDirectory();
    final encryptedBytes = await backupFile.readAsBytes();

    // 1. Decrypt and verify MAC tag
    final decryptedZipBytes = await _cryptoService.decryptArchive(
      encryptedBytes: encryptedBytes,
      password: password,
    );

    // 2. Decode zip archive
    final archive = ZipDecoder().decodeBytes(decryptedZipBytes);

    // 3. Read & validate manifest
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) {
      throw const InvalidBackupFormatException('Backup archive is missing manifest metadata');
    }

    final manifestJson = utf8.decode(manifestFile.content as List<int>);
    final manifest = BackupManifest.fromJson(manifestJson);

    // 4. Restore SQLite database file
    final dbArchiveFile = archive.findFile('fuel_service_log.sqlite');
    if (dbArchiveFile != null) {
      final targetDbFile = File(p.join(baseDir.path, 'fuel_service_log.sqlite'));
      await targetDbFile.writeAsBytes(dbArchiveFile.content as List<int>, flush: true);
    }

    // 5. Restore vault files
    for (final file in archive.files) {
      if (file.name.startsWith('vault/') && !file.name.endsWith('/')) {
        final targetPath = p.join(baseDir.path, file.name);
        final parentDir = Directory(p.dirname(targetPath));
        if (!await parentDir.exists()) {
          await parentDir.create(recursive: true);
        }
        final targetFile = File(targetPath);
        await targetFile.writeAsBytes(file.content as List<int>, flush: true);
      }
    }

    return manifest;
  }
}
