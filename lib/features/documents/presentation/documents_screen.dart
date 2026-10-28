import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../shell/presentation/vehicle_selector_app_bar.dart';
import '../data/documents_repository.dart';
import '../domain/document_expiry_calculator.dart';
import 'document_detail_screen.dart';
import 'document_form_screen.dart';
import 'providers/documents_providers.dart';
import 'quick_show_screen.dart';
import 'vault_lock_view.dart';
import 'vault_settings_dialog.dart';

enum DocumentFilter {
  all,
  quickShow,
  vehicleOnly,
  driverOnly,
}

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  DocumentFilter _filter = DocumentFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lockState = ref.watch(vaultLockNotifierProvider);

    return Scaffold(
      appBar: VehicleAppBar(
        title: l10n.navDocuments,
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Quick Show (Police Check)',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QuickShowScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.security_rounded),
            tooltip: 'Vault Security Settings',
            onPressed: () => VaultSettingsDialog.show(context),
          ),
          if (lockState.asData?.value == true)
            IconButton(
              icon: const Icon(Icons.lock_outline_rounded),
              tooltip: 'Lock Vault Now',
              onPressed: () {
                ref.read(vaultLockNotifierProvider.notifier).lock();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vault locked'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
        ],
      ),
      body: lockState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Security error: $err')),
        data: (isUnlocked) {
          if (!isUnlocked) {
            return const VaultLockView();
          }
          return _buildUnlockedVaultContent();
        },
      ),
      floatingActionButton: lockState.asData?.value == true
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DocumentFormScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Document'),
            )
          : null,
    );
  }

  Widget _buildUnlockedVaultContent() {
    final docsAsync = ref.watch(documentsStreamProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return docsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading documents: $err')),
      data: (docs) {
        final totalCount = docs.length;
        final expiringSoonCount = docs
            .where((d) => d.expiryStatus == DocumentExpiryStatus.expiringSoon)
            .length;
        final expiredCount = docs
            .where((d) => d.expiryStatus == DocumentExpiryStatus.expired)
            .length;
        final quickShowCount = docs.where((d) => d.document.isQuickShow).length;

        // Apply filter
        final filteredDocs = docs.where((d) {
          switch (_filter) {
            case DocumentFilter.all:
              return true;
            case DocumentFilter.quickShow:
              return d.document.isQuickShow;
            case DocumentFilter.vehicleOnly:
              return d.document.vehicleId != null;
            case DocumentFilter.driverOnly:
              return d.document.vehicleId == null;
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
                      label: 'Total',
                      count: totalCount,
                      color: colorScheme.primary,
                      icon: Icons.folder_shared_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildKpiCard(
                      label: 'Expiring',
                      count: expiringSoonCount,
                      color: Colors.amber.shade700,
                      icon: Icons.access_time_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildKpiCard(
                      label: 'Expired',
                      count: expiredCount,
                      color: colorScheme.error,
                      icon: Icons.error_outline_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildKpiCard(
                      label: 'Quick Show',
                      count: quickShowCount,
                      color: Colors.teal,
                      icon: Icons.shield_rounded,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const QuickShowScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Filter Chips Bar
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip('All Documents', DocumentFilter.all),
                    const SizedBox(width: 8),
                    _buildFilterChip('Quick Show', DocumentFilter.quickShow),
                    const SizedBox(width: 8),
                    _buildFilterChip('Vehicle Docs', DocumentFilter.vehicleOnly),
                    const SizedBox(width: 8),
                    _buildFilterChip('Driver / Personal', DocumentFilter.driverOnly),
                  ],
                ),
              ),
            ),

            // Document List
            if (filteredDocs.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(docs.isEmpty),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = filteredDocs[index];
                      return _buildDocumentCard(doc);
                    },
                    childCount: filteredDocs.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                label,
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
      ),
    );
  }

  Widget _buildFilterChip(String label, DocumentFilter filter) {
    final isSelected = _filter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filter = filter);
        }
      },
    );
  }

  Widget _buildDocumentCard(DocumentWithDetails item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final doc = item.document;
    final docType = item.documentType;
    final vehicle = item.vehicle;
    final status = item.expiryStatus;
    final days = item.daysUntilExpiry;

    final (badgeColor, statusText) = switch (status) {
      DocumentExpiryStatus.expired => (
          colorScheme.error,
          days == 0 ? 'Expired today' : 'Expired ${days?.abs()}d ago'
        ),
      DocumentExpiryStatus.expiringSoon => (
          Colors.amber.shade800,
          days == 0 ? 'Expires today' : 'Expires in ${days}d'
        ),
      DocumentExpiryStatus.valid => (
          Colors.green.shade700,
          'Valid (${days}d left)'
        ),
      DocumentExpiryStatus.noExpiry => (
          colorScheme.outline,
          'Lifetime'
        ),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DocumentDetailScreen(documentId: doc.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Document Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      docType.isVehicleSpecific
                          ? Icons.directions_car_filled_rounded
                          : Icons.badge_rounded,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title & Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (doc.documentNumber != null &&
                            doc.documentNumber!.isNotEmpty)
                          Text(
                            doc.documentNumber!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const SizedBox(height: 4),
                        // Vehicle or Driver Label
                        Row(
                          children: [
                            Icon(
                              vehicle != null
                                  ? Icons.directions_car_outlined
                                  : Icons.person_outline_rounded,
                              size: 14,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                vehicle != null
                                    ? '${vehicle.make} ${vehicle.model}'
                                    : 'Driver / Personal Document',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.65),
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
                  // Popup menu
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'quick_show') {
                        await ref
                            .read(documentsRepositoryProvider)
                            .toggleQuickShow(doc.id, !doc.isQuickShow);
                      } else if (value == 'edit') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DocumentFormScreen(
                              existingDocumentId: doc.id,
                            ),
                          ),
                        );
                      } else if (value == 'delete') {
                        _confirmDelete(context, doc.id);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'quick_show',
                        child: Row(
                          children: [
                            Icon(
                              doc.isQuickShow
                                  ? Icons.shield_rounded
                                  : Icons.shield_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              doc.isQuickShow
                                  ? 'Remove from Quick Show'
                                  : 'Add to Quick Show',
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: const Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Document'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: const Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              // Bottom row badges
              Row(
                children: [
                  // Expiry status chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          status == DocumentExpiryStatus.expired
                              ? Icons.error_outline_rounded
                              : status == DocumentExpiryStatus.expiringSoon
                                  ? Icons.access_time_rounded
                                  : Icons.check_circle_outline_rounded,
                          color: badgeColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Quick Show badge
                  if (doc.isQuickShow) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.teal.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_rounded, color: Colors.teal, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Quick Show',
                            style: TextStyle(
                              color: Colors.teal,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  // Photo count indicator
                  if (item.files.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.files.length}p',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isTrulyEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_shared_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isTrulyEmpty ? 'No Documents in Vault' : 'No matching documents',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isTrulyEmpty
                  ? 'Safely store encrypted vehicle and driver documents like Driving License, Registration, Tax Token, and Smart Card.'
                  : 'Try selecting a different filter above.',
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
                      builder: (_) => const DocumentFormScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Document'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document?'),
        content: const Text(
          'Are you sure you want to delete this document from your vault?',
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
      await ref.read(documentsRepositoryProvider).softDeleteDocument(docId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted')),
        );
      }
    }
  }
}
