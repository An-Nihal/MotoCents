import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

enum VaultAutoLockTimeout {
  immediately(0, 'Immediately'),
  oneMinute(60, '1 minute'),
  fiveMinutes(300, '5 minutes'),
  never(-1, 'Never');

  final int seconds;
  final String label;
  const VaultAutoLockTimeout(this.seconds, this.label);

  static VaultAutoLockTimeout fromSeconds(int seconds) {
    return VaultAutoLockTimeout.values.firstWhere(
      (e) => e.seconds == seconds,
      orElse: () => VaultAutoLockTimeout.immediately,
    );
  }
}

class VaultAuthService {
  VaultAuthService({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication();

  static const _pinHashKey = 'vault_pin_hash_v1';
  static const _pinSaltKey = 'vault_pin_salt_v1';
  static const _isLockEnabledKey = 'vault_is_lock_enabled_v1';
  static const _biometricsEnabledKey = 'vault_biometrics_enabled_v1';
  static const _autoLockSecondsKey = 'vault_auto_lock_seconds_v1';

  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;

  DateTime? _lastUnlockedAt;

  /// Checks if vault lock is enabled by the user.
  Future<bool> isLockEnabled() async {
    final value = await _secureStorage.read(key: _isLockEnabledKey);
    return value == 'true';
  }

  /// Checks if a PIN has been configured.
  Future<bool> hasPin() async {
    final hash = await _secureStorage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  /// Checks if biometrics is supported and enabled for vault unlock.
  Future<bool> isBiometricsEnabled() async {
    final value = await _secureStorage.read(key: _biometricsEnabledKey);
    return value == 'true';
  }

  /// Checks if hardware biometrics is available on device.
  Future<bool> canUseBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Gets configured auto-lock timeout.
  Future<VaultAutoLockTimeout> getAutoLockTimeout() async {
    final value = await _secureStorage.read(key: _autoLockSecondsKey);
    final seconds = int.tryParse(value ?? '0') ?? 0;
    return VaultAutoLockTimeout.fromSeconds(seconds);
  }

  /// Sets auto-lock timeout.
  Future<void> setAutoLockTimeout(VaultAutoLockTimeout timeout) async {
    await _secureStorage.write(
      key: _autoLockSecondsKey,
      value: timeout.seconds.toString(),
    );
  }

  /// Sets up or updates the vault PIN.
  Future<void> setPin(String pin, {bool enableBiometrics = true}) async {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    final saltBase64 = base64Encode(saltBytes);

    final hash = await _hashPin(pin, saltBase64);

    await _secureStorage.write(key: _pinSaltKey, value: saltBase64);
    await _secureStorage.write(key: _pinHashKey, value: hash);
    await _secureStorage.write(key: _isLockEnabledKey, value: 'true');
    if (enableBiometrics && await canUseBiometrics()) {
      await _secureStorage.write(key: _biometricsEnabledKey, value: 'true');
    }
  }

  /// Toggles biometric unlock.
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _biometricsEnabledKey,
      value: enabled.toString(),
    );
  }

  /// Completely disables vault lock and clears stored PIN.
  Future<void> disableLock() async {
    await _secureStorage.write(key: _isLockEnabledKey, value: 'false');
    await _secureStorage.delete(key: _pinHashKey);
    await _secureStorage.delete(key: _pinSaltKey);
    await _secureStorage.delete(key: _biometricsEnabledKey);
    _lastUnlockedAt = null;
  }

  /// Verifies entered PIN against stored salted hash.
  Future<bool> verifyPin(String enteredPin) async {
    final saltBase64 = await _secureStorage.read(key: _pinSaltKey);
    final storedHash = await _secureStorage.read(key: _pinHashKey);

    if (saltBase64 == null || storedHash == null) {
      return false;
    }

    final enteredHash = await _hashPin(enteredPin, saltBase64);
    final isValid = enteredHash == storedHash;
    if (isValid) {
      markUnlocked();
    }
    return isValid;
  }

  /// Prompts for biometric authentication (Fingerprint / Face ID).
  Future<bool> authenticateWithBiometrics({String? reason}) async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason ?? 'Unlock your Document Vault',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (isAuthenticated) {
        markUnlocked();
      }
      return isAuthenticated;
    } catch (_) {
      return false;
    }
  }

  /// Marks the current session as unlocked.
  void markUnlocked() {
    _lastUnlockedAt = DateTime.now();
  }

  /// Explicitly locks the vault.
  void lock() {
    _lastUnlockedAt = null;
  }

  /// Checks if the vault is currently unlocked, respecting auto-lock duration.
  Future<bool> isSessionUnlocked() async {
    final isLocked = await isLockEnabled();
    if (!isLocked) {
      return true; // No lock enabled
    }

    if (_lastUnlockedAt == null) {
      return false;
    }

    final timeout = await getAutoLockTimeout();
    if (timeout == VaultAutoLockTimeout.never) {
      return true;
    }

    final elapsed = DateTime.now().difference(_lastUnlockedAt!).inSeconds;
    if (elapsed > timeout.seconds) {
      _lastUnlockedAt = null;
      return false;
    }

    return true;
  }

  Future<String> _hashPin(String pin, String saltBase64) async {
    final bytes = utf8.encode('$saltBase64::$pin');
    final sha = Sha256();
    final hashResult = await sha.hash(bytes);
    return hashResult.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
