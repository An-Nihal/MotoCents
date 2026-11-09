import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motocents/core/database/app_database.dart';
import 'package:motocents/core/notifications/notification_service.dart';
import 'package:motocents/core/providers/database_provider.dart';
import 'package:motocents/core/providers/vehicles_provider.dart';
import 'package:motocents/features/documents/data/documents_repository.dart';
import 'package:motocents/features/documents/domain/vault_auth_service.dart';
import 'package:motocents/features/documents/domain/vault_crypto_service.dart';

final vaultCryptoServiceProvider = Provider<VaultCryptoService>((ref) {
  return VaultCryptoService();
});

final vaultAuthServiceProvider = Provider<VaultAuthService>((ref) {
  return VaultAuthService();
});

final documentsRepositoryProvider = Provider<DocumentsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final crypto = ref.watch(vaultCryptoServiceProvider);
  final notif = ref.watch(notificationServiceProvider);
  return DocumentsRepository(db, cryptoService: crypto, notificationService: notif);
});

/// Tracks vault lock state in memory for the active app session using AsyncNotifier.
class VaultLockNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final auth = ref.watch(vaultAuthServiceProvider);
    final isLocked = await auth.isLockEnabled();
    if (!isLocked) return true;
    return auth.isSessionUnlocked();
  }

  /// Checks if vault lock is enabled on device and if current session is already unlocked.
  Future<void> checkLockStatus() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final auth = ref.read(vaultAuthServiceProvider);
      final isLockEnabled = await auth.isLockEnabled();
      if (!isLockEnabled) return true;
      return auth.isSessionUnlocked();
    });
  }

  /// Attempts to unlock with PIN.
  Future<bool> unlockWithPin(String pin) async {
    final auth = ref.read(vaultAuthServiceProvider);
    final success = await auth.verifyPin(pin);
    if (success) {
      state = const AsyncValue.data(true);
    }
    return success;
  }

  /// Attempts to unlock with biometric authentication.
  Future<bool> unlockWithBiometrics() async {
    final auth = ref.read(vaultAuthServiceProvider);
    final success = await auth.authenticateWithBiometrics();
    if (success) {
      state = const AsyncValue.data(true);
    }
    return success;
  }

  /// Manually locks the vault.
  void lock() {
    ref.read(vaultAuthServiceProvider).lock();
    state = const AsyncValue.data(false);
  }
}

final vaultLockNotifierProvider =
    AsyncNotifierProvider<VaultLockNotifier, bool>(VaultLockNotifier.new);

/// Watches documents matching current selected vehicle (or all if none selected).
final documentsStreamProvider =
    StreamProvider.autoDispose<List<DocumentWithDetails>>((ref) {
  final repo = ref.watch(documentsRepositoryProvider);
  final selectedVehicle = ref.watch(currentVehicleProvider);
  return repo.watchDocuments(
    vehicleId: selectedVehicle?.id,
    includeDriverDocs: true,
  );
});

/// Watches all quick show documents (police check mode).
final quickShowDocumentsProvider =
    StreamProvider.autoDispose<List<DocumentWithDetails>>((ref) {
  final repo = ref.watch(documentsRepositoryProvider);
  return repo.watchDocuments(quickShowOnly: true);
});

/// Watches document types (default + custom).
final documentTypesProvider =
    StreamProvider.autoDispose<List<DocumentTypeData>>((ref) {
  final repo = ref.watch(documentsRepositoryProvider);
  return repo.watchDocumentTypes();
});

/// Watches total count of expiring / expired documents for Home screen badge.
final expiringDocumentsCountProvider = StreamProvider.autoDispose<int>((ref) {
  final repo = ref.watch(documentsRepositoryProvider);
  final selectedVehicle = ref.watch(currentVehicleProvider);
  return repo.watchExpiringCount(vehicleId: selectedVehicle?.id);
});
