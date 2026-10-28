import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/settings_provider.dart';
import '../data/expenses_repository.dart';
import '../domain/expense_category_helper.dart';
import 'expense_form_screen.dart';
import 'providers/expenses_providers.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final String expenseId;

  const ExpenseDetailScreen({
    super.key,
    required this.expenseId,
  });

  @override
  ConsumerState<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final repo = ref.watch(expensesRepositoryProvider);

    return FutureBuilder<ExpenseWithDetails?>(
      future: repo.getExpenseById(widget.expenseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final details = snapshot.data;
        if (details == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Expense')),
            body: const Center(child: Text('Expense record not found')),
          );
        }

        final exp = details.expense;
        final cat = details.category;
        final vehicle = details.vehicle;
        final catColor = ExpenseCategoryHelper.getCategoryColor(cat.code, cat.name);
        final catIcon = ExpenseCategoryHelper.getCategoryIcon(cat.code, cat.name);
        final dateFormat = DateFormat('EEEE, dd MMMM yyyy, hh:mm a');

        return Scaffold(
          appBar: AppBar(
            title: Text(cat.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit Expense',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ExpenseFormScreen(
                        existingExpenseId: exp.id,
                      ),
                    ),
                  );
                  setState(() {});
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete Expense',
                onPressed: () => _confirmDelete(context, exp.id),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount Banner Card
              Card(
                color: catColor.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: catColor.withValues(alpha: 0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: catColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(catIcon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${settings.currencySymbol} ${exp.amount.toStringAsFixed(2)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: catColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        context,
                        icon: Icons.calendar_today_rounded,
                        label: 'Date & Time',
                        value: dateFormat.format(exp.date),
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(
                        context,
                        icon: Icons.directions_car_rounded,
                        label: 'Vehicle',
                        value: '${vehicle.name} (${vehicle.plateNumber})',
                      ),
                      if (exp.odometer != null) ...[
                        const Divider(height: 24),
                        _buildDetailRow(
                          context,
                          icon: Icons.speed_rounded,
                          label: 'Odometer Reading',
                          value: '${exp.odometer!.toStringAsFixed(0)} ${settings.distanceUnit}',
                        ),
                      ],
                      if (exp.notes != null && exp.notes!.trim().isNotEmpty) ...[
                        const Divider(height: 24),
                        _buildDetailRow(
                          context,
                          icon: Icons.notes_rounded,
                          label: 'Notes',
                          value: exp.notes!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Decrypted Receipt Image (if present)
              if (exp.receiptPath != null) ...[
                const SizedBox(height: 16),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.receipt_long_rounded, color: colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Attached Receipt (Decrypted)',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AspectRatio(
                        aspectRatio: 16 / 10,
                        child: FutureBuilder<Uint8List>(
                          future: repo.decryptReceipt(exp.receiptPath!),
                          builder: (context, fileSnapshot) {
                            if (fileSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (fileSnapshot.hasError || !fileSnapshot.hasData) {
                              return Center(child: Text('Error: ${fileSnapshot.error}'));
                            }
                            return InteractiveViewer(
                              minScale: 0.8,
                              maxScale: 3.5,
                              child: Image.memory(
                                fileSnapshot.data!,
                                fit: BoxFit.contain,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, String expenseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text(
          'Are you sure you want to delete this expense record?',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(expensesRepositoryProvider).softDeleteExpense(expenseId);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense deleted')),
        );
      }
    }
  }
}
