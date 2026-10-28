import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../garage/presentation/vehicle_form_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    // 1. Mark onboarding as completed
    await ref.read(settingsProvider.notifier).setOnboardingCompleted(true);

    if (!mounted) return;

    // 2. Check if a vehicle already exists
    final db = ref.read(databaseProvider);
    final vehicles = await (db.select(db.vehicles)..where((v) => v.deletedAt.isNull())).get();

    if (!mounted) return;

    if (vehicles.isEmpty) {
      // Guide user to add their first vehicle
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const VehicleFormScreen(),
        ),
      );
    }

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final slides = [
      _OnboardingSlideData(
        icon: Icons.local_gas_station_rounded,
        color: AppColors.primaryAmber,
        title: l10n.onboardingWelcomeTitle,
        description: l10n.onboardingWelcomeDesc,
        badge: 'PRECISION FUEL LOG',
      ),
      _OnboardingSlideData(
        icon: Icons.build_circle_rounded,
        color: AppColors.secondaryTeal,
        title: l10n.onboardingMaintenanceTitle,
        description: l10n.onboardingMaintenanceDesc,
        badge: 'MAINTENANCE & VAULT',
      ),
      _OnboardingSlideData(
        icon: Icons.security_rounded,
        color: AppColors.success,
        title: l10n.onboardingPrivacyTitle,
        description: l10n.onboardingPrivacyDesc,
        badge: 'ZERO CLOUD • 100% PRIVATE',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          if (_currentPage < slides.length - 1)
            TextButton(
              onPressed: _completeOnboarding,
              child: Text(
                l10n.skip,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: slide.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: slide.color.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            slide.badge,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: slide.color,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Icon Graphic Container
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: slide.color.withValues(alpha: 0.14),
                            boxShadow: [
                              BoxShadow(
                                color: slide.color.withValues(alpha: 0.15),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: index == 0
                              ? Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: Image.asset(
                                      'assets/images/app_logo.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                )
                              : Icon(
                                  slide.icon,
                                  size: 72,
                                  color: slide.color,
                                ),
                        ),
                        const SizedBox(height: 40),

                        // Title
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation & Indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicator Dots
                  Row(
                    children: List.generate(slides.length, (idx) {
                      final isActive = idx == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        height: 8,
                        width: isActive ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Next or Get Started Button
                  FilledButton.icon(
                    onPressed: () {
                      if (_currentPage < slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                    icon: Icon(
                      _currentPage < slides.length - 1
                          ? Icons.arrow_forward_rounded
                          : Icons.check_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _currentPage < slides.length - 1 ? l10n.next : l10n.getStarted,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlideData {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String badge;

  const _OnboardingSlideData({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.badge,
  });
}

