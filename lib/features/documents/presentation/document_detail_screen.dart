import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/documents_repository.dart';
import '../domain/document_expiry_calculator.dart';
import 'document_form_screen.dart';
import 'providers/documents_providers.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  final String documentId;

  const DocumentDetailScreen({
    super.key,
    required this.documentId,
  });

  @override
  ConsumerState<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  int _selectedPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final repo = ref.watch(documentsRepositoryProvider);

    return FutureBuilder<DocumentWithDetails?>(
      future: repo.getDocumentById(widget.documentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final docWithDetails = snapshot.data;
        if (docWithDetails == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Document')),
            body: const Center(child: Text('Document not found')),
          );
        }

        final doc = docWithDetails.document;
        final docType = docWithDetails.documentType;
        final vehicle = docWithDetails.vehicle;
        final files = docWithDetails.files;
        final expiryStatus = docWithDetails.expiryStatus;
        final dateFormat = DateFormat.yMMMMd();

        final (badgeColor, statusText) = switch (expiryStatus) {
          DocumentExpiryStatus.expired => (
              colorScheme.error,
              'Expired (${(docWithDetails.daysUntilExpiry ?? 0).abs()} days ago)',
            ),
          DocumentExpiryStatus.expiringSoon => (
              Colors.amber.shade800,
              'Expiring Soon (${docWithDetails.daysUntilExpiry} days left)',
            ),
          DocumentExpiryStatus.valid => (
              Colors.green.shade700,
              'Valid (${docWithDetails.daysUntilExpiry} days left)',
            ),
          DocumentExpiryStatus.noExpiry => (
              colorScheme.outline,
              'Lifetime / No Expiry',
            ),
        };

        return Scaffold(
          appBar: AppBar(
            title: Text(doc.title),
            actions: [
              IconButton(
                icon: Icon(
                  doc.isQuickShow ? Icons.shield_rounded : Icons.shield_outlined,
                  color: doc.isQuickShow ? colorScheme.primary : null,
                ),
                tooltip: 'Toggle Quick Show',
                onPressed: () async {
                  await repo.toggleQuickShow(doc.id, !doc.isQuickShow);
                  setState(() {});
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit Document',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DocumentFormScreen(
                        existingDocumentId: doc.id,
                      ),
                    ),
                  );
                  setState(() {});
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete Document',
                onPressed: () => _confirmDelete(context, doc.id),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Decrypted Image Viewer Card
                if (files.isNotEmpty) ...[
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 10,
                          child: FutureBuilder<Uint8List>(
                            future: repo.decryptFile(
                              files[_selectedPageIndex.clamp(0, files.length - 1)]
                                  .filePath,
                            ),
                            builder: (context, fileSnapshot) {
                              if (fileSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (fileSnapshot.hasError || !fileSnapshot.hasData) {
                                return Center(
                                  child: Text('Error: ${fileSnapshot.error}'),
                                );
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
                        if (files.length > 1)
                          Container(
                            color: colorScheme.surfaceContainerHighest,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(files.length, (idx) {
                                final isSelected = idx == _selectedPageIndex;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: ChoiceChip(
                                    label: Text(
                                      idx == 0
                                          ? 'Front Side'
                                          : idx == 1
                                              ? 'Back Side'
                                              : 'Page ${idx + 1}',
                                    ),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _selectedPageIndex = idx);
                                      }
                                    },
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Expiry Status Banner Card
                Card(
                  color: badgeColor.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: badgeColor.withValues(alpha: 0.4)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          expiryStatus == DocumentExpiryStatus.expired
                              ? Icons.error_outline_rounded
                              : expiryStatus == DocumentExpiryStatus.expiringSoon
                                  ? Icons.access_time_rounded
                                  : Icons.check_circle_outline_rounded,
                          color: badgeColor,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                statusText,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: badgeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (doc.expiryDate != null)
                                Text(
                                  'Expires on ${dateFormat.format(doc.expiryDate!)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.7),
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
                          icon: Icons.category_outlined,
                          label: 'Document Type',
                          value: docType.name,
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(
                          context,
                          icon: Icons.tag_rounded,
                          label: 'Document Number',
                          value: doc.documentNumber ?? 'Not specified',
                          trailing: doc.documentNumber != null
                              ? IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 18),
                                  tooltip: 'Copy Number',
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: doc.documentNumber!),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Document number copied'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                )
                              : null,
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(
                          context,
                          icon: Icons.account_balance_outlined,
                          label: 'Issuing Authority',
                          value: doc.issuingAuthority ?? 'Not specified',
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(
                          context,
                          icon: Icons.directions_car_outlined,
                          label: 'Vehicle Association',
                          value: vehicle != null
                              ? '${vehicle.name} (${vehicle.plateNumber})'
                              : 'Driver / Personal Document',
                        ),
                        if (doc.issueDate != null) ...[
                          const Divider(height: 24),
                          _buildDetailRow(
                            context,
                            icon: Icons.calendar_today_outlined,
                            label: 'Issue Date',
                            value: dateFormat.format(doc.issueDate!),
                          ),
                        ],
                        const Divider(height: 24),
                        _buildDetailRow(
                          context,
                          icon: Icons.notifications_active_outlined,
                          label: 'Reminders',
                          value: doc.expiryDate != null
                              ? '${doc.reminderDaysBefore} days before expiry'
                              : 'No expiry reminders',
                        ),
                      ],
                    ),
                  ),
                ),

                // Quick Show Switch Card
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    secondary: Icon(
                      Icons.shield_rounded,
                      color: doc.isQuickShow ? colorScheme.primary : null,
                    ),
                    title: const Text('Quick Show Mode'),
                    subtitle: const Text(
                      'Includes this document in full-screen traffic police verification',
                    ),
                    value: doc.isQuickShow,
                    onChanged: (val) async {
                      await repo.toggleQuickShow(doc.id, val);
                      setState(() {});
                    },
                  ),
                ),

                // Notes Card (if present)
                if (doc.notes != null && doc.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.notes_rounded,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Notes',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            doc.notes!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
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
    Widget? trailing,
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
        ?trailing,
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document?'),
        content: const Text(
          'Are you sure you want to delete this document from your vault? You can restore it later if needed.',
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
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted')),
        );
      }
    }
  }
}
