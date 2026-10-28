import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/vehicles_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../data/vehicles_repository.dart';
import 'vehicle_form_screen.dart';

class VehiclesListScreen extends ConsumerStatefulWidget {
  const VehiclesListScreen({super.key});

  @override
  ConsumerState<VehiclesListScreen> createState() => _VehiclesListScreenState();
}

class _VehiclesListScreenState extends ConsumerState<VehiclesListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  IconData _getVehicleIcon(String type) {
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

  void _openAddVehicle(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
    );
  }

  void _openEditVehicle(BuildContext context, VehicleData vehicle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VehicleFormScreen(vehicleToEdit: vehicle),
      ),
    );
  }

  void _confirmDelete(BuildContext context, VehicleData vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vehicle?'),
        content: Text(
          'Are you sure you want to remove "${vehicle.name}"? All associated logs will be kept in backup history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(vehiclesRepositoryProvider);
              await repo.softDelete(vehicle.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Vehicle "${vehicle.name}" removed'),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: AppColors.primaryAmberLight,
                      onPressed: () => repo.restore(vehicle.id),
                    ),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(vehiclesRepositoryProvider);
    final allVehiclesStream = repo.watchAllVehicles(includeArchived: true);
    final currentVehicle = ref.watch(currentVehicleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Garage'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryAmber,
          labelColor: AppColors.primaryAmber,
          tabs: const [
            Tab(text: 'Active Vehicles'),
            Tab(text: 'Archived'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddVehicle(context),
        backgroundColor: AppColors.primaryAmber,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Vehicle'),
      ),
      body: StreamBuilder<List<VehicleData>>(
        stream: allVehiclesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data ?? [];
          final active = all.where((v) => !v.isArchived).toList();
          final archived = all.where((v) => v.isArchived).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildVehicleList(context, active, isArchivedTab: false, currentVehicle: currentVehicle),
              _buildVehicleList(context, archived, isArchivedTab: true, currentVehicle: currentVehicle),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVehicleList(
    BuildContext context,
    List<VehicleData> list, {
    required bool isArchivedTab,
    required VehicleData? currentVehicle,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isArchivedTab ? Icons.archive_outlined : Icons.directions_car_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                isArchivedTab ? 'No archived vehicles' : 'No vehicles in garage',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                isArchivedTab
                    ? 'Archived vehicles you no longer drive will appear here.'
                    : 'Tap "Add Vehicle" below to get started.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final vehicle = list[index];
        final isSelected = currentVehicle?.id == vehicle.id;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isSelected
                          ? AppColors.primaryAmber.withValues(alpha: 0.2)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      backgroundImage: vehicle.photoPath != null
                          ? FileImage(File(vehicle.photoPath!))
                          : null,
                      child: vehicle.photoPath == null
                          ? Icon(
                              _getVehicleIcon(vehicle.vehicleType),
                              size: 28,
                              color: isSelected
                                  ? AppColors.primaryAmber
                                  : Theme.of(context).iconTheme.color,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  vehicle.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryAmber
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryAmberDark,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vehicle.plateNumber,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${vehicle.fuelType.toUpperCase()} • ${vehicle.initialOdometer.toStringAsFixed(0)} ${vehicle.distanceUnit} initial',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isSelected && !vehicle.isArchived)
                      TextButton.icon(
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Set Active'),
                        onPressed: () {
                          ref
                              .read(settingsProvider.notifier)
                              .setSelectedVehicleId(vehicle.id);
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Edit',
                      onPressed: () => _openEditVehicle(context, vehicle),
                    ),
                    IconButton(
                      icon: Icon(
                        vehicle.isArchived
                            ? Icons.unarchive_outlined
                            : Icons.archive_outlined,
                        size: 20,
                      ),
                      tooltip: vehicle.isArchived ? 'Unarchive' : 'Archive',
                      onPressed: () async {
                        final repo = ref.read(vehiclesRepositoryProvider);
                        await repo.setArchived(vehicle.id, !vehicle.isArchived);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: AppColors.error),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(context, vehicle),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
