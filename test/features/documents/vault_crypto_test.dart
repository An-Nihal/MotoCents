import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
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

void main() {
  late MockSecureStorage mockStorage;
  late VaultCryptoService cryptoService;

  setUp(() {
    mockStorage = MockSecureStorage();
    cryptoService = VaultCryptoService(secureStorage: mockStorage);
  });

  group('VaultCryptoService - AES-256-GCM', () {
    test('Round-trip encryption and decryption of string payload', () async {
      const plaintext = 'Driver License #DL-2024-998811 - John Doe';
      final plainBytes = Uint8List.fromList(utf8.encode(plaintext));

      final encrypted = await cryptoService.encryptBytes(plainBytes);

      // Verify payload is larger than nonce (12) + MAC (16)
      expect(encrypted.length, greaterThan(28));
      expect(encrypted, isNot(equals(plainBytes)));

      final decrypted = await cryptoService.decryptBytes(encrypted);
      expect(utf8.decode(decrypted), equals(plaintext));
    });

    test('Two encryptions of identical plaintext produce distinct ciphertexts (random IV/nonce)', () async {
      final sample = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

      final cipher1 = await cryptoService.encryptBytes(sample);
      final cipher2 = await cryptoService.encryptBytes(sample);

      expect(cipher1, isNot(equals(cipher2)));

      final dec1 = await cryptoService.decryptBytes(cipher1);
      final dec2 = await cryptoService.decryptBytes(cipher2);
      expect(dec1, equals(sample));
      expect(dec2, equals(sample));
    });

    test('Tampering with ciphertext triggers GCM authentication failure', () async {
      final sample = Uint8List.fromList(utf8.encode('Secret vehicle registration certificate'));
      final encrypted = await cryptoService.encryptBytes(sample);

      // Flip a bit in the ciphertext part
      final tampered = Uint8List.fromList(encrypted);
      tampered[tampered.length - 1] ^= 0xFF;

      expect(
        () async => await cryptoService.decryptBytes(tampered),
        throwsA(anything),
      );
    });

    test('Master key persists in secure storage across instances', () async {
      final key1 = await cryptoService.getOrCreateMasterKey();
      final key1Bytes = await key1.extractBytes();

      // Create a second service instance with the same storage
      final cryptoService2 = VaultCryptoService(secureStorage: mockStorage);
      final key2 = await cryptoService2.getOrCreateMasterKey();
      final key2Bytes = await key2.extractBytes();

      expect(key1Bytes, equals(key2Bytes));
    });
  });
}
