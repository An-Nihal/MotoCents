import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../documents/presentation/providers/documents_providers.dart';

class ManageDocumentTypesScreen extends ConsumerStatefulWidget {
  const ManageDocumentTypesScreen({super.key});

  @override
  ConsumerState<ManageDocumentTypesScreen> createState() =>
      _ManageDocumentTypesScreenState();
}

class _ManageDocumentTypesScreenState
    extends ConsumerState<ManageDocumentTypesScreen> {
  final _uuid = const Uuid();

  Future<void> _showAddDialog() async {
    final nameController = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_circle_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text('Add Document Type'),
              ],
            ),
            content: TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Document Type Name *',
                hintText: 'e.g. Pollution Under Control (PUC)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                errorText: error,
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
                    setDialogState(() => error = 'Please enter a document type name');
                    return;
                  }

                  final repo = ref.read(documentsRepositoryProvider);
                  await repo.createDocumentType(
                    DocumentTypesCompanion.insert(
                      id: _uuid.v4(),
                      name: name,
                      isCustom: const drift.Value(true),
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

  Future<void> _deleteDocumentType(DocumentTypeData type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document Type'),
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
      final repo = ref.read(documentsRepositoryProvider);
      await repo.softDeleteDocumentType(type.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.watch(documentsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Types'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Document Type',
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<DocumentTypeData>>(
        stream: repo.watchDocumentTypes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final types = snapshot.data!;
          if (types.isEmpty) {
            return const Center(child: Text('No document types available.'));
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
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description_rounded, color: Colors.blue, size: 20),
                ),
                title: Text(type.name, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                            onPressed: () => _deleteDocumentType(type),
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
