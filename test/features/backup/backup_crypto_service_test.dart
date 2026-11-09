import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocents/features/backup/data/backup_crypto_service.dart';

void main() {
  late BackupCryptoService cryptoService;

  setUp(() {
    cryptoService = BackupCryptoService();
  });

  group('BackupCryptoService', () {
    test('successfully encrypts and decrypts payload with correct password', () async {
      const originalString = 'Fuel & Service Log: confidential vehicle backup data 2026';
      final rawBytes = Uint8List.fromList(utf8.encode(originalString));
      const password = 'SecretPassword123!';

      final encryptedBytes = await cryptoService.encryptArchive(
        rawBytes: rawBytes,
        password: password,
      );

      expect(encryptedBytes.isNotEmpty, true);
      // Header check: 4-byte magic + 1-byte version
      expect(encryptedBytes.length, greaterThan(BackupCryptoService.headerTotalLength));
      expect(encryptedBytes[0], 0x46); // 'F'
      expect(encryptedBytes[1], 0x53); // 'S'
      expect(encryptedBytes[2], 0x4C); // 'L'
      expect(encryptedBytes[3], 0x42); // 'B'
      expect(encryptedBytes[4], 1);    // Version 1

      final decryptedBytes = await cryptoService.decryptArchive(
        encryptedBytes: encryptedBytes,
        password: password,
      );

      final decryptedString = utf8.decode(decryptedBytes);
      expect(decryptedString, equals(originalString));
    });

    test('fails decryption and throws InvalidBackupPasswordException with incorrect password', () async {
      final rawBytes = Uint8List.fromList(utf8.encode('Hello World'));
      final encryptedBytes = await cryptoService.encryptArchive(
        rawBytes: rawBytes,
        password: 'CorrectPassword1',
      );

      expect(
        () => cryptoService.decryptArchive(
          encryptedBytes: encryptedBytes,
          password: 'WrongPassword2',
        ),
        throwsA(isA<InvalidBackupPasswordException>()),
      );
    });

    test('throws InvalidBackupFormatException for truncated or invalid magic payload', () async {
      // Too short
      expect(
        () => cryptoService.decryptArchive(
          encryptedBytes: Uint8List.fromList([1, 2, 3]),
          password: 'AnyPassword',
        ),
        throwsA(isA<InvalidBackupFormatException>()),
      );

      // Wrong magic header
      final fakeBytes = Uint8List(50);
      fakeBytes[0] = 0x58; // 'X'
      expect(
        () => cryptoService.decryptArchive(
          encryptedBytes: fakeBytes,
          password: 'AnyPassword',
        ),
        throwsA(isA<InvalidBackupFormatException>()),
      );
    });

    test('throws exception when payload ciphertext or MAC is corrupted', () async {
      final rawBytes = Uint8List.fromList(utf8.encode('Data integrity test'));
      final encryptedBytes = await cryptoService.encryptArchive(
        rawBytes: rawBytes,
        password: 'Password123',
      );

      // Tamper with the last byte of the ciphertext
      final corrupted = Uint8List.fromList(encryptedBytes);
      corrupted[corrupted.length - 1] ^= 0xFF;

      expect(
        () => cryptoService.decryptArchive(
          encryptedBytes: corrupted,
          password: 'Password123',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
