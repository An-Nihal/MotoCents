import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'database_provider.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final String currency;
  final String currencySymbol;
  final String distanceUnit;
  final String volumeUnit;
  final String economyUnit;
  final String? selectedVehicleId;
  final bool onboardingCompleted;
  final bool serviceRemindersEnabled;
  final bool documentRemindersEnabled;
  final String reminderTimeOfDay;
  final int vaultTimeoutMinutes;
  final bool isLoaded;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('en'),
    this.currency = 'BDT',
    this.currencySymbol = '৳',
    this.distanceUnit = 'km',
    this.volumeUnit = 'L',
    this.economyUnit = 'km/L',
    this.selectedVehicleId,
    this.onboardingCompleted = false,
    this.serviceRemindersEnabled = true,
    this.documentRemindersEnabled = true,
    this.reminderTimeOfDay = '09:00',
    this.vaultTimeoutMinutes = 1,
    this.isLoaded = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    String? currency,
    String? currencySymbol,
    String? distanceUnit,
    String? volumeUnit,
    String? economyUnit,
    String? selectedVehicleId,
    bool? onboardingCompleted,
    bool? serviceRemindersEnabled,
    bool? documentRemindersEnabled,
    String? reminderTimeOfDay,
    int? vaultTimeoutMinutes,
    bool? isLoaded,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      volumeUnit: volumeUnit ?? this.volumeUnit,
      economyUnit: economyUnit ?? this.economyUnit,
      selectedVehicleId: selectedVehicleId ?? this.selectedVehicleId,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      serviceRemindersEnabled: serviceRemindersEnabled ?? this.serviceRemindersEnabled,
      documentRemindersEnabled: documentRemindersEnabled ?? this.documentRemindersEnabled,
      reminderTimeOfDay: reminderTimeOfDay ?? this.reminderTimeOfDay,
      vaultTimeoutMinutes: vaultTimeoutMinutes ?? this.vaultTimeoutMinutes,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _loadSettings();
    return const SettingsState();
  }

  Future<void> _loadSettings() async {
    try {
      final db = ref.read(databaseProvider);
      final rows = await db.select(db.settings).get();
      final map = {for (var r in rows) r.id: r.value};

      ThemeMode mode = ThemeMode.system;
      if (map['theme_mode'] == 'light') mode = ThemeMode.light;
      if (map['theme_mode'] == 'dark') mode = ThemeMode.dark;

      final lang = map['language'] ?? 'en';
      final selectedVehicle = map['selected_vehicle_id'];

      final onboardingCompleted = map['onboarding_completed'] == 'true';
      final serviceReminders = map['service_reminders_enabled'] != 'false';
      final documentReminders = map['document_reminders_enabled'] != 'false';
      final reminderTime = map['reminder_time_of_day'] ?? '09:00';
      final vaultTimeout = int.tryParse(map['vault_timeout_minutes'] ?? '1') ?? 1;

      state = state.copyWith(
        themeMode: mode,
        locale: Locale(lang),
        currency: map['currency'] ?? 'BDT',
        currencySymbol: map['currency_symbol'] ?? '৳',
        distanceUnit: map['distance_unit'] ?? 'km',
        volumeUnit: map['volume_unit'] ?? 'L',
        economyUnit: map['economy_unit'] ?? 'km/L',
        selectedVehicleId:
            (selectedVehicle != null && selectedVehicle.isNotEmpty)
                ? selectedVehicle
                : null,
        onboardingCompleted: onboardingCompleted,
        serviceRemindersEnabled: serviceReminders,
        documentRemindersEnabled: documentReminders,
        reminderTimeOfDay: reminderTime,
        vaultTimeoutMinutes: vaultTimeout,
        isLoaded: true,
      );
    } catch (_) {
      state = state.copyWith(isLoaded: true);
    }
  }

  Future<void> _persist(String id, String value) async {
    final db = ref.read(databaseProvider);
    await db.into(db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(
            id: id,
            value: value,
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final value = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await _persist('theme_mode', value);
  }

  Future<void> setLocale(Locale loc) async {
    state = state.copyWith(locale: loc);
    await _persist('language', loc.languageCode);
  }

  Future<void> setSelectedVehicleId(String? id) async {
    state = state.copyWith(selectedVehicleId: id);
    await _persist('selected_vehicle_id', id ?? '');
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    state = state.copyWith(onboardingCompleted: completed);
    await _persist('onboarding_completed', completed ? 'true' : 'false');
  }

  Future<void> setCurrency({required String currency, required String symbol}) async {
    state = state.copyWith(currency: currency, currencySymbol: symbol);
    await _persist('currency', currency);
    await _persist('currency_symbol', symbol);
  }

  Future<void> setDistanceUnit(String unit) async {
    state = state.copyWith(distanceUnit: unit);
    await _persist('distance_unit', unit);
  }

  Future<void> setVolumeUnit(String unit) async {
    state = state.copyWith(volumeUnit: unit);
    await _persist('volume_unit', unit);
  }

  Future<void> setEconomyUnit(String unit) async {
    state = state.copyWith(economyUnit: unit);
    await _persist('economy_unit', unit);
  }

  Future<void> setServiceRemindersEnabled(bool enabled) async {
    state = state.copyWith(serviceRemindersEnabled: enabled);
    await _persist('service_reminders_enabled', enabled ? 'true' : 'false');
  }

  Future<void> setDocumentRemindersEnabled(bool enabled) async {
    state = state.copyWith(documentRemindersEnabled: enabled);
    await _persist('document_reminders_enabled', enabled ? 'true' : 'false');
  }

  Future<void> setReminderTimeOfDay(String time) async {
    state = state.copyWith(reminderTimeOfDay: time);
    await _persist('reminder_time_of_day', time);
  }

  Future<void> setVaultTimeoutMinutes(int minutes) async {
    state = state.copyWith(vaultTimeoutMinutes: minutes);
    await _persist('vault_timeout_minutes', minutes.toString());
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
