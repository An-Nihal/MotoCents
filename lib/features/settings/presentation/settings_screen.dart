import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../backup/presentation/backup_restore_screen.dart';
import '../../backup/presentation/providers/backup_providers.dart';
import '../../documents/presentation/vault_settings_dialog.dart';
import '../../reports/presentation/reports_screen.dart';
import 'manage_document_types_screen.dart';
import 'manage_expense_categories_screen.dart';
import 'manage_service_types_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const List<Map<String, String>> _supportedCurrencies = [
    {'code': 'BDT', 'symbol': '৳', 'name': 'Bangladeshi Taka (৳)'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar (\$)'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro (€)'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound (£)'},
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee (₹)'},
    {'code': 'CAD', 'symbol': 'CA\$', 'name': 'Canadian Dollar (CA\$)'},
    {'code': 'AUD', 'symbol': 'AU\$', 'name': 'Australian Dollar (AU\$)'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen (¥)'},
    {'code': 'AED', 'symbol': 'AED', 'name': 'UAE Dirham (AED)'},
    {'code': 'SAR', 'symbol': 'SAR', 'name': 'Saudi Riyal (SAR)'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final isBackupReminderEnabled = ref.watch(backupReminderEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Section 1: Appearance & Language
          _buildSectionHeader(context, 'Appearance & Language'),
          ListTile(
            leading: _buildIcon(Icons.palette_rounded, AppColors.secondaryTeal),
            title: Text(l10n.theme),
            subtitle: Text(
              settings.themeMode == ThemeMode.light
                  ? l10n.themeLight
                  : settings.themeMode == ThemeMode.dark
                      ? l10n.themeDark
                      : l10n.themeSystem,
            ),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              underline: const SizedBox(),
              items: [
                DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.themeSystem)),
                DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.themeLight)),
                DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.themeDark)),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(mode);
                }
              },
            ),
          ),
          ListTile(
            leading: _buildIcon(Icons.language_rounded, AppColors.primaryAmber),
            title: Text(l10n.language),
            subtitle: Text(settings.locale.languageCode == 'bn' ? 'বাংলা (Bangla)' : 'English'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'en', label: Text('EN')),
                ButtonSegment(value: 'bn', label: Text('বাং')),
              ],
              selected: {settings.locale.languageCode},
              onSelectionChanged: (selected) {
                ref.read(settingsProvider.notifier).setLocale(Locale(selected.first));
              },
            ),
          ),
          const Divider(height: 24),

          // Section 2: Units & Currencies
          _buildSectionHeader(context, l10n.units),
          ListTile(
            leading: _buildIcon(Icons.monetization_on_rounded, Colors.green),
            title: Text(l10n.currency),
            subtitle: Text('${settings.currency} (${settings.currencySymbol})'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showCurrencyPicker(context, ref, settings.currency),
          ),
          ListTile(
            leading: _buildIcon(Icons.straighten_rounded, Colors.blue),
            title: Text(l10n.distanceUnit),
            subtitle: Text(settings.distanceUnit == 'km' ? 'Kilometers (km)' : 'Miles (mi)'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'km', label: Text('km')),
                ButtonSegment(value: 'mi', label: Text('mi')),
              ],
              selected: {settings.distanceUnit},
              onSelectionChanged: (selected) {
                ref.read(settingsProvider.notifier).setDistanceUnit(selected.first);
              },
            ),
          ),
          ListTile(
            leading: _buildIcon(Icons.local_gas_station_rounded, Colors.deepOrange),
            title: Text(l10n.volumeUnit),
            subtitle: Text(settings.volumeUnit == 'L' ? 'Litres (L)' : 'Gallons (gal)'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'L', label: Text('L')),
                ButtonSegment(value: 'gal', label: Text('gal')),
              ],
              selected: {settings.volumeUnit},
              onSelectionChanged: (selected) {
                ref.read(settingsProvider.notifier).setVolumeUnit(selected.first);
              },
            ),
          ),
          ListTile(
            leading: _buildIcon(Icons.speed_rounded, Colors.indigo),
            title: Text(l10n.economyUnit),
            subtitle: Text(settings.economyUnit),
            trailing: DropdownButton<String>(
              value: settings.economyUnit,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'km/L', child: Text('km/L')),
                DropdownMenuItem(value: 'L/100km', child: Text('L/100km')),
                DropdownMenuItem(value: 'MPG', child: Text('MPG')),
              ],
              onChanged: (val) {
                if (val != null) {
                  ref.read(settingsProvider.notifier).setEconomyUnit(val);
                }
              },
            ),
          ),
          const Divider(height: 24),

          // Section 3: Notifications & Preferences
          _buildSectionHeader(context, l10n.notifications),
          SwitchListTile(
            secondary: _buildIcon(Icons.notifications_active_rounded, Colors.amber),
            title: Text(l10n.serviceReminders),
            subtitle: const Text('Notify when distance or interval is reached'),
            value: settings.serviceRemindersEnabled,
            activeThumbColor: theme.colorScheme.primary,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setServiceRemindersEnabled(val);
            },
          ),
          SwitchListTile(
            secondary: _buildIcon(Icons.event_available_rounded, Colors.blue),
            title: Text(l10n.documentReminders),
            subtitle: const Text('Notify 30, 15, 7, and 1 day before expiry'),
            value: settings.documentRemindersEnabled,
            activeThumbColor: theme.colorScheme.primary,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setDocumentRemindersEnabled(val);
            },
          ),
          SwitchListTile(
            secondary: _buildIcon(Icons.backup_rounded, Colors.teal),
            title: Text(l10n.backupReminder),
            subtitle: const Text('Remind if no backup created in 30 days'),
            value: isBackupReminderEnabled,
            activeThumbColor: theme.colorScheme.primary,
            onChanged: (val) {
              ref.read(backupReminderEnabledProvider.notifier).setEnabled(val);
            },
          ),
          ListTile(
            leading: _buildIcon(Icons.schedule_rounded, Colors.purple),
            title: Text(l10n.reminderTime),
            subtitle: Text(settings.reminderTimeOfDay),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _pickReminderTime(context, ref, settings.reminderTimeOfDay),
          ),
          const Divider(height: 24),

          // Section 4: Vault Security
          _buildSectionHeader(context, l10n.vaultSecurity),
          ListTile(
            leading: _buildIcon(Icons.shield_rounded, AppColors.success),
            title: const Text('Document Vault Lock & PIN'),
            subtitle: const Text('Biometrics, PIN code, and auto-lock timeout'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => VaultSettingsDialog.show(context),
          ),
          const Divider(height: 24),

          // Section 5: Custom Categories & Types Management
          _buildSectionHeader(context, l10n.manageMetadata),
          ListTile(
            leading: _buildIcon(Icons.build_rounded, Colors.amber),
            title: Text(l10n.manageServiceTypes),
            subtitle: const Text('View built-in and create custom service items'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageServiceTypesScreen()),
              );
            },
          ),
          ListTile(
            leading: _buildIcon(Icons.category_rounded, Colors.purple),
            title: Text(l10n.manageExpenseCategories),
            subtitle: const Text('Parking, tolls, fines, and custom expenses'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageExpenseCategoriesScreen()),
              );
            },
          ),
          ListTile(
            leading: _buildIcon(Icons.description_rounded, Colors.blue),
            title: Text(l10n.manageDocumentTypes),
            subtitle: const Text('Licenses, tokens, fitness, and custom docs'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageDocumentTypesScreen()),
              );
            },
          ),
          const Divider(height: 24),

          // Section 6: Data & Backup shortcuts
          _buildSectionHeader(context, 'Data & Backup'),
          ListTile(
            leading: _buildIcon(Icons.picture_as_pdf_rounded, Colors.teal),
            title: Text(l10n.reportsTitle),
            subtitle: Text(l10n.reportsSubtitle),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            },
          ),
          ListTile(
            leading: _buildIcon(Icons.security_rounded, Colors.amber.shade800),
            title: Text(l10n.backupTitle),
            subtitle: Text(l10n.backupSubtitle),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
              );
            },
          ),
          const Divider(height: 24),

          // Section 7: About & Privacy
          _buildSectionHeader(context, 'About & Privacy'),
          ListTile(
            leading: _buildIcon(Icons.lock_outline_rounded, AppColors.success),
            title: Text(l10n.privacyPolicy),
            subtitle: const Text('Zero telemetry. Zero servers. 100% offline & encrypted.'),
          ),
          const ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Icon(Icons.info_outline_rounded),
            ),
            title: Text('Version'),
            subtitle: Text('1.0.0 (Build 1) • Production Release'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primaryAmber,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Future<void> _showCurrencyPicker(
    BuildContext context,
    WidgetRef ref,
    String currentCode,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Currency'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _supportedCurrencies.length,
            itemBuilder: (context, index) {
              final item = _supportedCurrencies[index];
              final isSelected = item['code'] == currentCode;
              return ListTile(
                title: Text(item['name']!),
                trailing: isSelected
                    ? const Icon(Icons.check_rounded, color: Colors.green)
                    : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).setCurrency(
                        currency: item['code']!,
                        symbol: item['symbol']!,
                      );
                  Navigator.of(ctx).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickReminderTime(
    BuildContext context,
    WidgetRef ref,
    String currentTimeStr,
  ) async {
    final parts = currentTimeStr.split(':');
    final initialHour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 9) : 9;
    final initialMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );

    if (picked != null) {
      final hourStr = picked.hour.toString().padLeft(2, '0');
      final minStr = picked.minute.toString().padLeft(2, '0');
      await ref.read(settingsProvider.notifier).setReminderTimeOfDay('$hourStr:$minStr');
    }
  }
}

