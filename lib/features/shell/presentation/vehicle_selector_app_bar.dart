import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/vehicles_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../garage/presentation/vehicle_form_screen.dart';
import '../../garage/presentation/vehicles_list_screen.dart';

class VehicleAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showVehicleSelector;

  const VehicleAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showVehicleSelector = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  IconData _getVehicleIcon(String? type) {
    switch (type) {
      case 'motorcycle':
        return Icons.two_wheeler_rounded;
      case 'cng':
        return Icons.electric_rickshaw_rounded;
      case 'truck':
        return Icons.local_shipping_rounded;
      case 'microbus':
        return Icons.airport_shuttle_rounded;
      default:
        return Icons.directions_car_rounded;
    }
  }

  void _showVehiclePicker(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final vehicles = ref.read(activeVehiclesStreamProvider).value ?? [];
    final currentVehicle = ref.read(currentVehicleProvider);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.selectVehicle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const VehiclesListScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.garage_rounded, size: 18),
                      label: const Text('Manage'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (vehicles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        l10n.noVehiclesTitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: vehicles.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final v = vehicles[index];
                        final isSelected = currentVehicle?.id == v.id;

                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? AppColors.primaryAmber.withValues(alpha: 0.2)
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Icon(
                              _getVehicleIcon(v.vehicleType),
                              color: isSelected
                                  ? AppColors.primaryAmber
                                  : Theme.of(context).iconTheme.color,
                            ),
                          ),
                          title: Text(
                            v.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${v.plateNumber} • ${v.fuelType.toUpperCase()}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primaryAmber,
                                )
                              : null,
                          onTap: () {
                            ref
                                .read(settingsProvider.notifier)
                                .setSelectedVehicleId(v.id);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const VehicleFormScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Another Vehicle'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentVehicle = ref.watch(currentVehicleProvider);

    return AppBar(
      titleSpacing: 16,
      title: showVehicleSelector && currentVehicle != null
          ? InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showVehiclePicker(context, ref),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getVehicleIcon(currentVehicle.vehicleType),
                        size: 20,
                        color: AppColors.primaryAmber,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentVehicle.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          currentVehicle.plateNumber,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                    ),
                  ],
                ),
              ),
            )
          : Text(title),
      actions: [
        ...?actions,
        const SizedBox(width: 8),
      ],
    );
  }
}
