import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/providers/database_provider.dart';
import '../../data/backup_crypto_service.dart';
import '../../data/backup_service.dart';

const int backupNotificationId = 999999;

final backupCryptoServiceProvider = Provider<BackupCryptoService>((ref) {
  return BackupCryptoService();
});

final backupServiceProvider = Provider<BackupService>((ref) {
  final db = ref.watch(databaseProvider);
  final crypto = ref.watch(backupCryptoServiceProvider);
  return BackupService(db: db, cryptoService: crypto);
});

class LastBackupNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    _loadFromDb();
    return null;
  }

  Future<void> _loadFromDb() async {
    try {
      final db = ref.read(databaseProvider);
      final setting = await (db.select(db.settings)
            ..where((t) => t.id.equals('last_backup_date')))
          .getSingleOrNull();

      if (setting != null) {
        final parsed = DateTime.tryParse(setting.value);
        if (parsed != null) {
          state = parsed;
        }
      }
    } catch (_) {}
  }

  Future<void> setLastBackup(DateTime date) async {
    state = date;
    try {
      final db = ref.read(databaseProvider);
      await db.into(db.settings).insertOnConflictUpdate(
            SettingsCompanion.insert(
              id: 'last_backup_date',
              value: date.toIso8601String(),
              updatedAt: Value(DateTime.now()),
            ),
          );

      final isEnabled = ref.read(backupReminderEnabledProvider);
      if (isEnabled) {
        final notifications = ref.read(notificationServiceProvider);
        await notifications.scheduleNotification(
          id: backupNotificationId,
          title: 'Backup Reminder',
          body: 'It has been 30 days since your last encrypted backup. Create a backup to keep your records safe.',
          scheduledDate: date.add(const Duration(days: 30)),
        );
      }
    } catch (_) {}
  }
}

final lastBackupDateProvider =
    NotifierProvider<LastBackupNotifier, DateTime?>(LastBackupNotifier.new);

class BackupReminderNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadFromDb();
    return true; // enabled by default
  }

  Future<void> _loadFromDb() async {
    try {
      final db = ref.read(databaseProvider);
      final setting = await (db.select(db.settings)
            ..where((t) => t.id.equals('backup_reminder_enabled')))
          .getSingleOrNull();

      if (setting != null) {
        state = setting.value == 'true';
      }
    } catch (_) {}
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    try {
      final db = ref.read(databaseProvider);
      await db.into(db.settings).insertOnConflictUpdate(
            SettingsCompanion.insert(
              id: 'backup_reminder_enabled',
              value: enabled ? 'true' : 'false',
              updatedAt: Value(DateTime.now()),
            ),
          );

      final notifications = ref.read(notificationServiceProvider);
      if (!enabled) {
        await notifications.cancelNotification(backupNotificationId);
      } else {
        final lastBackup = ref.read(lastBackupDateProvider) ?? DateTime.now();
        final scheduledDate = lastBackup.add(const Duration(days: 30));
        if (scheduledDate.isAfter(DateTime.now())) {
          await notifications.scheduleNotification(
            id: backupNotificationId,
            title: 'Backup Reminder',
            body: 'It has been 30 days since your last encrypted backup. Create a backup to keep your records safe.',
            scheduledDate: scheduledDate,
          );
        }
      }
    } catch (_) {}
  }
}

final backupReminderEnabledProvider =
    NotifierProvider<BackupReminderNotifier, bool>(BackupReminderNotifier.new);

final backupDueReminderProvider = Provider.autoDispose<bool>((ref) {
  final enabled = ref.watch(backupReminderEnabledProvider);
  if (!enabled) return false;

  final lastBackup = ref.watch(lastBackupDateProvider);
  if (lastBackup == null) return true; // never backed up
  final diff = DateTime.now().difference(lastBackup);
  return diff.inDays >= 30;
});
