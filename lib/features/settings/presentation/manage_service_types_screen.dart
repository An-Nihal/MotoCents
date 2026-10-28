import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../service/data/services_repository.dart';

class ManageServiceTypesScreen extends ConsumerStatefulWidget {
  const ManageServiceTypesScreen({super.key});

  @override
  ConsumerState<ManageServiceTypesScreen> createState() => _ManageServiceTypesScreenState();
}

class _ManageServiceTypesScreenState extends ConsumerState<ManageServiceTypesScreen> {
  final _uuid = const Uuid();

  Future<void> _showAddDialog() async {
    final nameController = TextEditingController();
    final distController = TextEditingController();
    final monthController = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_circle_outline, color: Colors.amber),
                SizedBox(width: 8),
                Text('Add Service Type'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Service Name *',
                      hintText: 'e.g. Gear Oil Replacement',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      errorText: error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: distController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Default Interval Distance (km)',
                      hintText: 'e.g. 5000 (optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: monthController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Default Interval (Months)',
                      hintText: 'e.g. 6 (optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    setDialogState(() => error = 'Please enter a service name');
                    return;
                  }

                  final dist = double.tryParse(distController.text.trim());
                  final months = int.tryParse(monthController.text.trim());

                  final repo = ref.read(servicesRepositoryProvider);
                  await repo.createServiceType(
                    ServiceTypesCompanion.insert(
                      id: _uuid.v4(),
                      name: name,
                      isCustom: const drift.Value(true),
                      defaultDistanceInterval: drift.Value(dist),
                      defaultMonthInterval: drift.Value(months),
                    ),
                  );

                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteServiceType(ServiceTypeData type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Custom Service Type'),
        content: Text('Are you sure you want to delete "${type.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(servicesRepositoryProvider);
      await repo.softDeleteServiceType(type.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.watch(servicesRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Types'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Custom Type',
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<ServiceTypeData>>(
        stream: repo.watchServiceTypes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final types = snapshot.data!;
          if (types.isEmpty) {
            return const Center(child: Text('No service types available.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: types.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final type = types[index];
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.build_rounded, color: Colors.amber, size: 20),
                ),
                title: Text(type.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: type.defaultDistanceInterval != null || type.defaultMonthInterval != null
                    ? Text(
                        [
                          if (type.defaultDistanceInterval != null)
                            'Every ${type.defaultDistanceInterval!.toStringAsFixed(0)} km',
                          if (type.defaultMonthInterval != null)
                            'Every ${type.defaultMonthInterval} mos',
                        ].join(' • '),
                        style: theme.textTheme.bodySmall,
                      )
                    : null,
                trailing: type.isCustom
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'CUSTOM',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                            onPressed: () => _deleteServiceType(type),
                          ),
                        ],
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'DEFAULT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
