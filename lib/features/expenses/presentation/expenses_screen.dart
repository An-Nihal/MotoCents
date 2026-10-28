import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../shell/presentation/vehicle_selector_app_bar.dart';
import '../data/expenses_repository.dart';
import '../domain/expense_category_helper.dart';
import 'expense_detail_screen.dart';
import 'expense_form_screen.dart';
import 'providers/expenses_providers.dart';

enum ExpensePeriodFilter {
  all('All'),
  thisMonth('This Month'),
  lastMonth('Last Month'),
  thisYear('This Year');

  final String label;
  const ExpensePeriodFilter(this.label);

  String getLocalizedLabel(AppLocalizations l10n) {
    switch (this) {
      case ExpensePeriodFilter.all:
        return l10n.filterAll;
      case ExpensePeriodFilter.thisMonth:
        return l10n.thisMonth;
      case ExpensePeriodFilter.lastMonth:
        return l10n.lastMonth;
      case ExpensePeriodFilter.thisYear:
        return l10n.thisYear;
    }
  }
}

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  ExpensePeriodFilter _periodFilter = ExpensePeriodFilter.all;
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final expensesAsync = ref.watch(expensesStreamProvider);
    final categories = ref.watch(expenseCategoriesProvider).asData?.value ?? [];

    return Scaffold(
      appBar: VehicleAppBar(
        title: l10n.expenses,
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading expenses: $err')),
        data: (allExpenses) {
          final now = DateTime.now();

          // Calculate KPI metrics
          final thisMonthExpenses = allExpenses.where((e) {
            return e.expense.date.year == now.year && e.expense.date.month == now.month;
          });
          final thisMonthTotal =
              thisMonthExpenses.fold<double>(0.0, (sum, e) => sum + e.expense.amount);
          final allTimeTotal =
              allExpenses.fold<double>(0.0, (sum, e) => sum + e.expense.amount);

          // Apply filters
          final filtered = allExpenses.where((e) {
            // Category filter
            if (_selectedCategoryId != null &&
                e.expense.categoryId != _selectedCategoryId) {
              return false;
            }

            // Period filter
            switch (_periodFilter) {
              case ExpensePeriodFilter.all:
                return true;
              case ExpensePeriodFilter.thisMonth:
                return e.expense.date.year == now.year &&
                    e.expense.date.month == now.month;
              case ExpensePeriodFilter.lastMonth:
                final lastMonthDate = DateTime(now.year, now.month - 1, 1);
                return e.expense.date.year == lastMonthDate.year &&
                    e.expense.date.month == lastMonthDate.month;
              case ExpensePeriodFilter.thisYear:
                return e.expense.date.year == now.year;
            }
          }).toList();

          return CustomScrollView(
            slivers: [
              // KPI Summary Strip
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      _buildKpiCard(
                        context,
                        title: l10n.thisMonth,
                        value:
                            '${settings.currencySymbol} ${thisMonthTotal.toStringAsFixed(0)}',
                        icon: Icons.calendar_today_rounded,
                        color: Colors.purple.shade600,
                      ),
                      const SizedBox(width: 10),
                      _buildKpiCard(
                        context,
                        title: l10n.allTimeSpend,
                        value:
                            '${settings.currencySymbol} ${allTimeTotal.toStringAsFixed(0)}',
                        icon: Icons.account_balance_wallet_rounded,
                        color: Colors.indigo.shade600,
                      ),
                      const SizedBox(width: 10),
                      _buildKpiCard(
                        context,
                        title: l10n.totalLogs,
                        value: '${allExpenses.length}',
                        icon: Icons.receipt_rounded,
                        color: Colors.teal.shade600,
                      ),
                    ],
                  ),
                ),
              ),

              // Filter Controls
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ExpensePeriodFilter.values.map((f) {
                            final isSelected = _periodFilter == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(f.getLocalizedLabel(l10n)),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _periodFilter = f);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Category Dropdown
                      if (categories.isNotEmpty)
                        DropdownButtonFormField<String?>(
                          isExpanded: true,
                          initialValue: _selectedCategoryId,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.filter_list_rounded, size: 20),
                          ),
                          hint: Text(l10n.filterByCategory),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(l10n.allCategories),
                            ),
                            ...categories.map((c) {
                              return DropdownMenuItem<String?>(
                                value: c.id,
                                child: Row(
                                  children: [
                                    Icon(
                                      ExpenseCategoryHelper.getCategoryIcon(c.code, c.name),
                                      size: 16,
                                      color: ExpenseCategoryHelper.getCategoryColor(
                                        c.code,
                                        c.name,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        c.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (val) => setState(() => _selectedCategoryId = val),
                        ),
                    ],
                  ),
                ),
              ),

              // Expense List
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(allExpenses.isEmpty),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = filtered[index];
                        return _buildExpenseCard(item);
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ExpenseFormScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addExpense),
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseWithDetails item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final exp = item.expense;
    final cat = item.category;
    final vehicle = item.vehicle;
    final catColor = ExpenseCategoryHelper.getCategoryColor(cat.code, cat.name);
    final catIcon = ExpenseCategoryHelper.getCategoryIcon(cat.code, cat.name);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ExpenseDetailScreen(expenseId: exp.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Category Icon Circle
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(catIcon, color: catColor, size: 22),
              ),
              const SizedBox(width: 14),

              // Title, Vehicle & Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (exp.notes != null && exp.notes!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        exp.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          dateFormat.format(exp.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            vehicle.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount & Receipt Icon
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${settings.currencySymbol} ${exp.amount.toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: catColor,
                    ),
                  ),
                  if (exp.receiptPath != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Receipt',
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              // Menu
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'edit') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ExpenseFormScreen(existingExpenseId: exp.id),
                      ),
                    );
                  } else if (val == 'delete') {
                    _confirmDelete(context, exp.id);
                  }
                },
                itemBuilder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(l10n.edit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isTrulyEmpty) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.payments_rounded,
                size: 56,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isTrulyEmpty ? l10n.noExpensesLogged : l10n.noMatchingExpenses,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isTrulyEmpty
                  ? l10n.expensesEmptyDesc
                  : l10n.expensesFilterEmptyDesc,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.65),
                  ),
            ),
            const SizedBox(height: 24),
            if (isTrulyEmpty)
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ExpenseFormScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.addExpense),
                style: FilledButton.styleFrom(backgroundColor: Colors.purple),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String expenseId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteExpenseTitle),
        content: Text(
          l10n.deleteExpenseConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(expensesRepositoryProvider).softDeleteExpense(expenseId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.expenseDeleted)),
        );
      }
    }
  }
}
