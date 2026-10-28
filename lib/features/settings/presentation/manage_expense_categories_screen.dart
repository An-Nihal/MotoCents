import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../expenses/presentation/providers/expenses_providers.dart';

class ManageExpenseCategoriesScreen extends ConsumerStatefulWidget {
  const ManageExpenseCategoriesScreen({super.key});

  @override
  ConsumerState<ManageExpenseCategoriesScreen> createState() =>
      _ManageExpenseCategoriesScreenState();
}

class _ManageExpenseCategoriesScreenState
    extends ConsumerState<ManageExpenseCategoriesScreen> {
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
                Icon(Icons.add_circle_outline, color: Colors.purple),
                SizedBox(width: 8),
                Text('Add Expense Category'),
              ],
            ),
            content: TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Category Name *',
                hintText: 'e.g. Detailing & Coating',
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
                    setDialogState(() => error = 'Please enter a category name');
                    return;
                  }

                  final repo = ref.read(expensesRepositoryProvider);
                  await repo.createCategory(
                    ExpenseCategoriesCompanion.insert(
                      id: _uuid.v4(),
                      name: name,
                      icon: const drift.Value('payments'),
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

  Future<void> _deleteCategory(ExpenseCategoryData category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
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
      final repo = ref.read(expensesRepositoryProvider);
      await repo.softDeleteCategory(category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.watch(expensesRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Category',
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<ExpenseCategoryData>>(
        stream: repo.watchCategories(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data!;
          if (categories.isEmpty) {
            return const Center(child: Text('No categories available.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.category_rounded, color: Colors.purple, size: 20),
                ),
                title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: cat.isCustom
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
                            onPressed: () => _deleteCategory(cat),
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
