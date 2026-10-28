import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_and_service_log/core/database/app_database.dart';
import 'package:fuel_and_service_log/features/backup/data/backup_crypto_service.dart';
import 'package:fuel_and_service_log/features/backup/data/backup_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late AppDatabase db;
  late BackupService backupService;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('fsl_backup_test_');

    // Create a mock SQLite file
    final mockDbFile = File(p.join(tempDir.path, 'fuel_service_log.sqlite'));
    await mockDbFile.writeAsString('SQLITE_MOCK_DATA');

    // Create a mock vault file
    final mockVaultDir = Directory(p.join(tempDir.path, 'vault'));
    await mockVaultDir.create(recursive: true);
    final mockDoc = File(p.join(mockVaultDir.path, 'doc_receipt.enc'));
    await mockDoc.writeAsString('VAULT_SECRET_BYTES');

    backupService = BackupService(
      db: db,
      cryptoService: BackupCryptoService(),
      getBaseDirectory: () async => tempDir,
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BackupService Integration', () {
    test('creates encrypted backup and restores archive with intact manifest', () async {
      // 1. Add sample vehicle
      await db.into(db.vehicles).insert(
            VehiclesCompanion.insert(
              id: 'v-1',
              name: 'Toyota Corolla',
              vehicleType: 'car',
              fuelType: 'petrol',
              plateNumber: 'DHK-1234',
            ),
          );

      const password = 'StrongMasterPassword123';

      // 2. Create backup
      final backupFile = await backupService.createBackup(password: password);
      expect(await backupFile.exists(), true);
      expect(backupFile.path.endsWith('.fslbackup'), true);

      // 3. Delete the mock files to ensure restore puts them back
      final mockDoc = File(p.join(tempDir.path, 'vault', 'doc_receipt.enc'));
      await mockDoc.delete();
      expect(await mockDoc.exists(), false);

      // 4. Restore backup
      final manifest = await backupService.restoreBackup(
        backupFile: backupFile,
        password: password,
      );

      // 5. Verify manifest data
      expect(manifest.vehicleCount, 1);
      expect(manifest.schemaVersion, 1);

      // 6. Verify restored vault file
      expect(await mockDoc.exists(), true);
      expect(await mockDoc.readAsString(), 'VAULT_SECRET_BYTES');
    });

    test('fails restore when incorrect password is provided', () async {
      const password = 'StrongPassword456';
      final backupFile = await backupService.createBackup(password: password);

      expect(
        () => backupService.restoreBackup(
          backupFile: backupFile,
          password: 'WrongPassword789',
        ),
        throwsA(isA<InvalidBackupPasswordException>()),
      );
    });
  });
}
