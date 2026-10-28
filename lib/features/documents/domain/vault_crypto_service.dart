import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Cryptographic service providing AES-256-GCM authenticated encryption
/// for document files stored on disk.
///
/// Encrypted file format:
/// [12-byte Nonce / IV] + [16-byte GCM Authentication Tag (MAC)] + [Ciphertext]
class VaultCryptoService {
  VaultCryptoService({
    FlutterSecureStorage? secureStorage,
    AesGcm? cipher,
    Future<Directory> Function()? getBaseDirectory,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _cipher = cipher ?? AesGcm.with256bits(),
        _getBaseDirectory = getBaseDirectory ?? getApplicationDocumentsDirectory;

  static const String _masterKeyStorageKey = 'vault_aes_256_master_key_v1';
  static const int _nonceLength = 12; // Standard 96-bit nonce for GCM
  static const int _macLength = 16;   // 128-bit authentication tag
  static const _uuid = Uuid();

  final FlutterSecureStorage _secureStorage;
  final AesGcm _cipher;
  final Future<Directory> Function() _getBaseDirectory;

  SecretKey? _cachedMasterKey;

  /// Retrieves or creates the 256-bit AES master key from secure storage.
  Future<SecretKey> getOrCreateMasterKey() async {
    if (_cachedMasterKey != null) {
      return _cachedMasterKey!;
    }

    final storedKeyBase64 = await _secureStorage.read(key: _masterKeyStorageKey);
    if (storedKeyBase64 != null && storedKeyBase64.isNotEmpty) {
      final keyBytes = base64Decode(storedKeyBase64);
      _cachedMasterKey = SecretKey(keyBytes);
      return _cachedMasterKey!;
    }

    // Generate fresh 256-bit (32 bytes) master key
    final random = Random.secure();
    final newKeyBytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      newKeyBytes[i] = random.nextInt(256);
    }

    await _secureStorage.write(
      key: _masterKeyStorageKey,
      value: base64Encode(newKeyBytes),
    );

    _cachedMasterKey = SecretKey(newKeyBytes);
    return _cachedMasterKey!;
  }

  /// Encrypts plaintext bytes using AES-256-GCM.
  /// Returns a binary payload: [12-byte nonce] + [16-byte MAC] + [ciphertext].
  Future<Uint8List> encryptBytes(Uint8List plainBytes) async {
    final secretKey = await getOrCreateMasterKey();
    final secretBox = await _cipher.encrypt(
      plainBytes,
      secretKey: secretKey,
    );

    final nonce = secretBox.nonce;
    final macBytes = secretBox.mac.bytes;
    final cipherText = secretBox.cipherText;

    final output = Uint8List(nonce.length + macBytes.length + cipherText.length);
    output.setRange(0, nonce.length, nonce);
    output.setRange(nonce.length, nonce.length + macBytes.length, macBytes);
    output.setRange(
      nonce.length + macBytes.length,
      output.length,
      cipherText,
    );

    return output;
  }

  /// Decrypts a binary payload encrypted with [encryptBytes].
  /// Throws [SecretBoxAuthenticationError] if data was tampered with.
  Future<Uint8List> decryptBytes(Uint8List encryptedPayload) async {
    if (encryptedPayload.length < _nonceLength + _macLength) {
      throw ArgumentError('Invalid encrypted payload: size is smaller than header');
    }

    final secretKey = await getOrCreateMasterKey();

    final nonce = encryptedPayload.sublist(0, _nonceLength);
    final macBytes = encryptedPayload.sublist(_nonceLength, _nonceLength + _macLength);
    final cipherText = encryptedPayload.sublist(_nonceLength + _macLength);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final decryptedBytes = await _cipher.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return Uint8List.fromList(decryptedBytes);
  }

  /// Encrypts raw file bytes and writes the result to an encrypted file
  /// inside the app-private vault directory.
  /// Returns the relative path from the app documents directory (e.g. `vault/doc_abc123.enc`).
  Future<String> saveEncryptedFile({
    required Uint8List rawBytes,
    required String fileExtension,
  }) async {
    final appDir = await _getBaseDirectory();
    final vaultDir = Directory(p.join(appDir.path, 'vault'));
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }

    final encryptedBytes = await encryptBytes(rawBytes);
    final fileName = 'doc_${_uuid.v4()}$fileExtension.enc';
    final targetFile = File(p.join(vaultDir.path, fileName));
    await targetFile.writeAsBytes(encryptedBytes, flush: true);

    return p.join('vault', fileName).replaceAll(r'\', '/');
  }

  /// Reads and decrypts an encrypted file from disk using its relative path.
  Future<Uint8List> readEncryptedFile(String relativePath) async {
    final appDir = await _getBaseDirectory();
    final file = File(p.join(appDir.path, relativePath));
    if (!await file.exists()) {
      throw FileNotFoundException('Encrypted file not found at: ${file.path}');
    }

    final encryptedBytes = await file.readAsBytes();
    return decryptBytes(encryptedBytes);
  }

  /// Deletes an encrypted file from disk.
  Future<bool> deleteEncryptedFile(String relativePath) async {
    try {
      final appDir = await _getBaseDirectory();
      final file = File(p.join(appDir.path, relativePath));
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {
      // Ignore deletion errors for missing files
    }
    return false;
  }
}

class FileNotFoundException implements Exception {
  final String message;
  FileNotFoundException(this.message);

  @override
  String toString() => 'FileNotFoundException: $message';
}
