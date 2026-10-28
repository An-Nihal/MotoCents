import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuel_and_service_log/features/documents/domain/vault_auth_service.dart';
import 'providers/documents_providers.dart';

class VaultSettingsDialog extends ConsumerStatefulWidget {
  const VaultSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const VaultSettingsDialog(),
    );
  }

  @override
  ConsumerState<VaultSettingsDialog> createState() => _VaultSettingsDialogState();
}

class _VaultSettingsDialogState extends ConsumerState<VaultSettingsDialog> {
  bool _isLockEnabled = false;
  bool _canBiometrics = false;
  bool _isBiometricsEnabled = false;
  VaultAutoLockTimeout _timeout = VaultAutoLockTimeout.immediately;
  bool _isLoading = true;

  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final auth = ref.read(vaultAuthServiceProvider);
    final isLocked = await auth.isLockEnabled();
    final canBio = await auth.canUseBiometrics();
    final isBio = await auth.isBiometricsEnabled();
    final timeout = await auth.getAutoLockTimeout();

    if (mounted) {
      setState(() {
        _isLockEnabled = isLocked;
        _canBiometrics = canBio;
        _isBiometricsEnabled = isBio;
        _timeout = timeout;
        _isLoading = false;
      });
    }
  }

  Future<void> _showSetPinDialog() async {
    _pinController.clear();
    _confirmPinController.clear();
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Set Vault PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create a 4-to-6 digit PIN to protect your vehicle and driver documents.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Enter PIN (4-6 digits)',
                  prefixIcon: Icon(Icons.pin_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm PIN',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final pin = _pinController.text.trim();
                final confirm = _confirmPinController.text.trim();

                if (pin.length < 4 || pin.length > 6) {
                  setDialogState(() {
                    errorMessage = 'PIN must be between 4 and 6 digits';
                  });
                  return;
                }

                if (pin != confirm) {
                  setDialogState(() {
                    errorMessage = 'PINs do not match';
                  });
                  return;
                }

                final messenger = ScaffoldMessenger.of(context);
                final auth = ref.read(vaultAuthServiceProvider);
                await auth.setPin(pin, enableBiometrics: _canBiometrics);
                await ref.read(vaultLockNotifierProvider.notifier).checkLockStatus();

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  await _loadSettings();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Vault PIN set successfully')),
                  );
                }
              },
              child: const Text('Save PIN'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _disableLock() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable Vault Lock?'),
        content: const Text(
          'Disabling the lock allows anyone with access to the app to view and manage your documents.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final auth = ref.read(vaultAuthServiceProvider);
      await auth.disableLock();
      await ref.read(vaultLockNotifierProvider.notifier).checkLockStatus();
      await _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vault lock disabled')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.shield_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Vault Security'),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('PIN Protection'),
                    subtitle: Text(
                      _isLockEnabled
                          ? 'Vault is protected by PIN'
                          : 'Vault is currently unlocked',
                    ),
                    value: _isLockEnabled,
                    onChanged: (enabled) {
                      if (enabled) {
                        _showSetPinDialog();
                      } else {
                        _disableLock();
                      }
                    },
                  ),
                  if (_isLockEnabled) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _showSetPinDialog,
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Change PIN'),
                      ),
                    ),
                    const Divider(),
                    if (_canBiometrics)
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Biometric Unlock'),
                        subtitle: const Text('Unlock with Fingerprint or Face ID'),
                        value: _isBiometricsEnabled,
                        onChanged: (enabled) async {
                          final auth = ref.read(vaultAuthServiceProvider);
                          await auth.setBiometricsEnabled(enabled);
                          setState(() {
                            _isBiometricsEnabled = enabled;
                          });
                        },
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Auto-Lock Timeout',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<VaultAutoLockTimeout>(
                      initialValue: _timeout,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: VaultAutoLockTimeout.values.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(t.label),
                        );
                      }).toList(),
                      onChanged: (newTimeout) async {
                        if (newTimeout != null) {
                          final auth = ref.read(vaultAuthServiceProvider);
                          await auth.setAutoLockTimeout(newTimeout);
                          setState(() {
                            _timeout = newTimeout;
                          });
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
