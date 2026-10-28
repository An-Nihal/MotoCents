import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../data/backup_crypto_service.dart';
import 'providers/backup_providers.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _isProcessing = false;
  String _processingMessage = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastBackup = ref.watch(lastBackupDateProvider);
    final isReminderEnabled = ref.watch(backupReminderEnabledProvider);
    final isBackupDue = ref.watch(backupDueReminderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status & Reminder Card
              _buildStatusCard(theme, lastBackup, isBackupDue, isReminderEnabled),
              const SizedBox(height: 16),

              // Create Backup Card
              _buildCreateBackupCard(theme),
              const SizedBox(height: 16),

              // Restore Backup Card
              _buildRestoreBackupCard(theme),
              const SizedBox(height: 24),

              // Offline & Security Guarantee Note
              _buildSecurityGuaranteeNote(theme),
              const SizedBox(height: 32),
            ],
          ),

          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: Center(
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _processingMessage,
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    ThemeData theme,
    DateTime? lastBackup,
    bool isBackupDue,
    bool isReminderEnabled,
  ) {
    final formattedDate = lastBackup != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(lastBackup)
        : 'Never';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  lastBackup != null ? Icons.check_circle : Icons.info_outline,
                  color: lastBackup != null ? Colors.green : Colors.orange,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Encrypted Backup',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (isBackupDue) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        lastBackup == null
                            ? 'No backup has been created yet. Create an encrypted backup now to safeguard your vehicle records.'
                            : 'It has been over 30 days since your last backup. Keep your latest logs safe by creating a new backup.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('30-Day Backup Reminder'),
              subtitle: const Text('Alert when records have not been backed up recently'),
              value: isReminderEnabled,
              activeThumbColor: theme.colorScheme.primary,
              onChanged: (val) {
                ref.read(backupReminderEnabledProvider.notifier).setEnabled(val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateBackupCard(ThemeData theme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.enhanced_encryption, color: Colors.amber, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Encrypted Backup',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'AES-256-GCM authenticated bundle',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Packages your SQLite database, all vehicle and fuel logs, expenses, service history, and encrypted document vault files into a secure .fslbackup file.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _promptCreateBackup,
              icon: const Icon(Icons.lock, size: 18),
              label: const Text('Create & Share Backup (.fslbackup)'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreBackupCard(ThemeData theme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.settings_backup_restore, color: Colors.blue, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Restore from Backup',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Import previous .fslbackup archive',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Select a .fslbackup file from Google Drive, iCloud, local storage, or a messaging app. Requires the password used when creating the backup.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _promptRestoreBackup,
              icon: const Icon(Icons.restore, size: 18),
              label: const Text('Select File & Restore'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityGuaranteeNote(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.privacy_tip_outlined, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '100% Offline & Private',
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your backup is encrypted with standard AES-256-GCM and PBKDF2 key derivation using 20,000 iterations. It never touches any external cloud servers unless you manually choose to send it via your personal cloud or email.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Backup Handlers ---

  Future<void> _promptCreateBackup() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscurePassword = true;
    String? errorMessage;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.lock_outline),
                SizedBox(width: 10),
                Text('Set Backup Password'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose a strong password to encrypt your backup file. You will need this password to restore your data.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final pwd = passwordController.text;
                  final confirm = confirmController.text;

                  if (pwd.length < 6) {
                    setDialogState(() => errorMessage = 'Password must be at least 6 characters');
                    return;
                  }
                  if (pwd != confirm) {
                    setDialogState(() => errorMessage = 'Passwords do not match');
                    return;
                  }

                  Navigator.of(ctx).pop(true);
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;

    final password = passwordController.text;
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Encrypting & Packaging Backup...';
    });

    try {
      final backupService = ref.read(backupServiceProvider);
      final backupFile = await backupService.createBackup(password: password);

      final now = DateTime.now();
      await ref.read(lastBackupDateProvider.notifier).setLastBackup(now);

      setState(() => _isProcessing = false);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(backupFile.path)],
          text: 'MotoCents Encrypted Backup (${DateFormat('dd MMM yyyy').format(now)})',
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup creation failed: $e')),
        );
      }
    }
  }

  Future<void> _promptRestoreBackup() async {
    try {
      final pickedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['fslbackup', 'zip'],
      );

      if (pickedFile == null) return;
      if (pickedFile.path == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not access selected backup file.')),
          );
        }
        return;
      }

      final backupFile = File(pickedFile.path!);

      if (!mounted) return;

      final passwordController = TextEditingController();
      bool obscurePassword = true;
      String? errorMessage;

      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange),
                  SizedBox(width: 10),
                  Text('Restore Backup'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'WARNING: Restoring will overwrite existing vehicles, logs, and document files with the contents of this backup.',
                        style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Enter the master password used when creating this backup file:',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Backup Password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    if (passwordController.text.isEmpty) {
                      setDialogState(() => errorMessage = 'Please enter password');
                      return;
                    }
                    Navigator.of(ctx).pop(true);
                  },
                  child: const Text('Restore Data'),
                ),
              ],
            );
          },
        ),
      );

      if (confirmed != true) return;

      final password = passwordController.text;
      setState(() {
        _isProcessing = true;
        _processingMessage = 'Verifying & Restoring Data...';
      });

      final backupService = ref.read(backupServiceProvider);
      final manifest = await backupService.restoreBackup(
        backupFile: backupFile,
        password: password,
      );

      setState(() => _isProcessing = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 10),
                Text('Restore Complete!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Backup created on: ${DateFormat('dd MMM yyyy, HH:mm').format(manifest.createdAt)}'),
                const Divider(),
                Text('• Vehicles restored: ${manifest.vehicleCount}'),
                Text('• Fuel fill-ups: ${manifest.fuelEntryCount}'),
                Text('• Service entries: ${manifest.serviceEntryCount}'),
                Text('• Other expenses: ${manifest.expenseCount}'),
                Text('• Vault documents: ${manifest.documentCount}'),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } on InvalidBackupPasswordException {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Decryption failed: Incorrect password.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on InvalidBackupFormatException catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid backup file: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
