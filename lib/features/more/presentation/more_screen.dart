import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../expenses/presentation/expenses_screen.dart';
import '../../garage/presentation/vehicles_list_screen.dart';
import '../../backup/presentation/backup_restore_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../smart/presentation/station_insights_screen.dart';
import '../../smart/presentation/trip_cost_calculator_screen.dart';
import '../../statistics/presentation/statistics_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.moreTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // App Logo and Branding Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  l10n.versionSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 8),

          _buildSectionHeader(context, l10n.garageAndVehicles),
          _buildTile(
            context,
            icon: Icons.garage_rounded,
            color: AppColors.primaryAmber,
            title: l10n.myGarage,
            subtitle: l10n.myGarageSubtitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const VehiclesListScreen(),
                ),
              );
            },
          ),
          const Divider(height: 24),

          _buildSectionHeader(context, l10n.features),
          _buildTile(
            context,
            icon: Icons.payments_rounded,
            color: Colors.purple,
            title: l10n.expenses,
            subtitle: l10n.expensesSubtitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ExpensesScreen(),
                ),
              );
            },
          ),
          _buildTile(
            context,
            icon: Icons.bar_chart_rounded,
            color: Colors.blue,
            title: l10n.statistics,
            subtitle: l10n.statisticsSubtitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StatisticsScreen(),
                ),
              );
            },
          ),
          _buildTile(
            context,
            icon: Icons.local_gas_station_rounded,
            color: Colors.indigo,
            title: l10n.stationInsights,
            subtitle: l10n.stationInsightsSubtitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StationInsightsScreen(),
                ),
              );
            },
          ),
          _buildTile(
            context,
            icon: Icons.route_rounded,
            color: Colors.deepOrange,
            title: l10n.tripCalculator,
            subtitle: l10n.tripCalculatorSubtitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TripCostCalculatorScreen(),
                ),
              );
            },
          ),
          _buildTile(
            context,
            icon: Icons.picture_as_pdf_rounded,
            color: Colors.teal,
            title: l10n.reports,
            subtitle: l10n.reportsSubtitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ReportsScreen(),
                ),
              );
            },
          ),
          _buildTile(
            context,
            icon: Icons.security_rounded,
            color: Colors.amber.shade800,
            title: l10n.backupTitle,
            subtitle: l10n.backupSubtitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BackupRestoreScreen(),
                ),
              );
            },
          ),
          const Divider(height: 24),
          _buildSectionHeader(context, l10n.settings),
          _buildTile(
            context,
            icon: Icons.settings_rounded,
            color: Colors.blueGrey,
            title: l10n.settings,
            subtitle: l10n.settingsSubtitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),

          // Language Selector
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Icon(Icons.language_rounded, color: AppColors.primaryAmber),
            ),
            title: Text(l10n.language),
            subtitle: Text(settings.locale.languageCode == 'bn' ? 'বাংলা' : 'English'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'en', label: Text('EN')),
                ButtonSegment(value: 'bn', label: Text('বাং')),
              ],
              selected: {settings.locale.languageCode},
              onSelectionChanged: (selected) {
                ref
                    .read(settingsProvider.notifier)
                    .setLocale(Locale(selected.first));
              },
            ),
          ),

          // Theme Selector
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Icon(Icons.palette_rounded, color: AppColors.secondaryTeal),
            ),
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
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(l10n.themeSystem),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(l10n.themeLight),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(l10n.themeDark),
                ),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(mode);
                }
              },
            ),
          ),

          const Divider(height: 24),
          _buildSectionHeader(context, l10n.aboutAndPrivacy),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Icon(Icons.security_rounded, color: AppColors.success),
            ),
            title: Text(l10n.localOnlyAndPrivate),
            subtitle: Text(l10n.localOnlyAndPrivateDesc),
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Icon(Icons.info_outline_rounded),
            ),
            title: Text(l10n.version),
            subtitle: Text(l10n.versionSubtitle),
          ),
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

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
