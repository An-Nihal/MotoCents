import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/documents_providers.dart';
import 'quick_show_screen.dart';

class VaultLockView extends ConsumerStatefulWidget {
  const VaultLockView({super.key});

  @override
  ConsumerState<VaultLockView> createState() => _VaultLockViewState();
}

class _VaultLockViewState extends ConsumerState<VaultLockView>
    with SingleTickerProviderStateMixin {
  final List<String> _enteredPin = [];
  bool _isError = false;
  bool _canBiometrics = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _checkBiometrics();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    final auth = ref.read(vaultAuthServiceProvider);
    final canBio = await auth.canUseBiometrics();
    final isEnabled = await auth.isBiometricsEnabled();
    if (mounted) {
      setState(() {
        _canBiometrics = canBio && isEnabled;
      });
      if (_canBiometrics) {
        _triggerBiometricAuth();
      }
    }
  }

  Future<void> _triggerBiometricAuth() async {
    final success =
        await ref.read(vaultLockNotifierProvider.notifier).unlockWithBiometrics();
    if (!success && mounted) {
      // Biometric failed or cancelled, stay on PIN pad
    }
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= 6) return;

    setState(() {
      _isError = false;
      _enteredPin.add(digit);
    });

    if (_enteredPin.length >= 4) {
      _attemptUnlock();
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _isError = false;
        _enteredPin.removeLast();
      });
    }
  }

  Future<void> _attemptUnlock() async {
    final pin = _enteredPin.join();
    final success =
        await ref.read(vaultLockNotifierProvider.notifier).unlockWithPin(pin);

    if (!success && mounted) {
      if (_enteredPin.length == 6) {
        // If 6 digits and failed, clear and shake
        _triggerErrorAnimation();
      }
    }
  }

  void _triggerErrorAnimation() {
    setState(() {
      _isError = true;
    });
    _shakeController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _enteredPin.clear();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Document Vault Locked',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your PIN to access secure documents',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 28),

            // PIN Indicator Dots
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final offset = _shakeController.value == 0
                    ? 0.0
                    : (1 - _shakeController.value) *
                        10 *
                        ((_shakeController.value * 20).toInt() % 2 == 0 ? 1 : -1);
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isError
                          ? colorScheme.error
                          : isFilled
                              ? colorScheme.primary
                              : colorScheme.outline.withValues(alpha: 0.3),
                      border: Border.all(
                        color: _isError
                            ? colorScheme.error
                            : isFilled
                                ? colorScheme.primary
                                : colorScheme.outline,
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),
            ),

            if (_isError) ...[
              const SizedBox(height: 12),
              Text(
                'Incorrect PIN. Try again.',
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Numeric Keypad
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Column(
                children: [
                  for (var row = 0; row < 3; row++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var col = 1; col <= 3; col++)
                            _buildKeyButton(
                              label: '${row * 3 + col}',
                              onTap: () =>
                                  _onDigitPressed('${row * 3 + col}'),
                            ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_canBiometrics)
                          _buildIconButton(
                            icon: Icons.fingerprint_rounded,
                            onTap: _triggerBiometricAuth,
                            tooltip: 'Unlock with Biometrics',
                          )
                        else
                          const SizedBox(width: 72, height: 72),
                        _buildKeyButton(
                          label: '0',
                          onTap: () => _onDigitPressed('0'),
                        ),
                        _buildIconButton(
                          icon: Icons.backspace_outlined,
                          onTap: _onDeletePressed,
                          tooltip: 'Backspace',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Show bypass for Traffic Police
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const QuickShowScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.shield_outlined, size: 18),
              label: const Text('Open Quick Show (Police Check)'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyButton({
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 72,
      height: 72,
      child: Tooltip(
        message: tooltip ?? '',
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: Icon(
                icon,
                size: 28,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
