import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class InvalidBackupPasswordException implements Exception {
  final String message;
  const InvalidBackupPasswordException([this.message = 'Invalid backup password or corrupted backup file']);
  @override
  String toString() => 'InvalidBackupPasswordException: $message';
}

class InvalidBackupFormatException implements Exception {
  final String message;
  const InvalidBackupFormatException([this.message = 'The selected file is not a valid Fuel and Service Log backup']);
  @override
  String toString() => 'InvalidBackupFormatException: $message';
}

class BackupCryptoService {
  static final List<int> magicBytes = utf8.encode('FSLB'); // Fuel & Service Log Backup
  static const int formatVersion = 1;
  static const int saltLength = 16;
  static const int nonceLength = 12; // 96-bit for AES-GCM
  static const int macLength = 16;   // 128-bit authentication tag
  static const int pbkdf2Iterations = 20000;
  static int get headerTotalLength => magicBytes.length + 1 + saltLength + nonceLength + macLength;

  final Pbkdf2 _pbkdf2;
  final AesGcm _cipher;

  BackupCryptoService({
    Pbkdf2? pbkdf2,
    AesGcm? cipher,
  })  : _pbkdf2 = pbkdf2 ??
            Pbkdf2(
              macAlgorithm: Hmac.sha256(),
              iterations: pbkdf2Iterations,
              bits: 256,
            ),
        _cipher = cipher ?? AesGcm.with256bits();

  /// Derives a 256-bit AES secret key from a user password and random salt.
  Future<SecretKey> _deriveKey(String password, Uint8List salt) async {
    final secretKey = await _pbkdf2.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    return secretKey;
  }

  /// Encrypts raw zip bytes into an authenticated `.fslbackup` binary payload.
  Future<Uint8List> encryptArchive({
    required Uint8List rawBytes,
    required String password,
  }) async {
    // Generate 16-byte random salt
    final random = Random.secure();
    final salt = Uint8List(saltLength);
    for (int i = 0; i < saltLength; i++) {
      salt[i] = random.nextInt(256);
    }

    // Derive 256-bit AES key
    final secretKey = await _deriveKey(password, salt);

    // Encrypt with AES-256-GCM
    final secretBox = await _cipher.encrypt(
      rawBytes,
      secretKey: secretKey,
    );

    final nonce = secretBox.nonce;
    final macBytes = secretBox.mac.bytes;
    final cipherText = secretBox.cipherText;

    // Build binary layout:
    // [4 bytes Magic] + [1 byte Version] + [16 bytes Salt] + [12 bytes Nonce] + [16 bytes MAC] + [Ciphertext]
    final headerLength = magicBytes.length + 1 + saltLength + nonceLength + macLength;
    final output = Uint8List(headerLength + cipherText.length);

    int offset = 0;
    output.setRange(offset, offset + magicBytes.length, magicBytes);
    offset += magicBytes.length;

    output[offset] = formatVersion;
    offset += 1;

    output.setRange(offset, offset + salt.length, salt);
    offset += salt.length;

    output.setRange(offset, offset + nonce.length, nonce);
    offset += nonce.length;

    output.setRange(offset, offset + macBytes.length, macBytes);
    offset += macBytes.length;

    output.setRange(offset, output.length, cipherText);

    return output;
  }

  /// Decrypts and authenticates an encrypted `.fslbackup` binary payload.
  Future<Uint8List> decryptArchive({
    required Uint8List encryptedBytes,
    required String password,
  }) async {
    final minLength = magicBytes.length + 1 + saltLength + nonceLength + macLength;
    if (encryptedBytes.length < minLength) {
      throw const InvalidBackupFormatException('Backup file is too short or corrupted');
    }

    // Verify magic bytes
    for (int i = 0; i < magicBytes.length; i++) {
      if (encryptedBytes[i] != magicBytes[i]) {
        throw const InvalidBackupFormatException('Invalid file signature. Not an FSL backup file.');
      }
    }

    int offset = magicBytes.length;
    final version = encryptedBytes[offset];
    offset += 1;

    if (version != formatVersion) {
      throw InvalidBackupFormatException('Unsupported backup version: $version');
    }

    final salt = encryptedBytes.sublist(offset, offset + saltLength);
    offset += saltLength;

    final nonce = encryptedBytes.sublist(offset, offset + nonceLength);
    offset += nonceLength;

    final macBytes = encryptedBytes.sublist(offset, offset + macLength);
    offset += macLength;

    final cipherText = encryptedBytes.sublist(offset);

    // Derive key using stored salt
    final secretKey = await _deriveKey(password, salt);

    // Decrypt and verify MAC tag
    try {
      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      final decrypted = await _cipher.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      return Uint8List.fromList(decrypted);
    } catch (_) {
      throw const InvalidBackupPasswordException('Incorrect password or file has been altered/corrupted');
    }
  }
}
