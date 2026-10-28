import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/vehicles_provider.dart';
import '../data/documents_repository.dart';
import 'providers/documents_providers.dart';

class DocumentFormScreen extends ConsumerStatefulWidget {
  final String? existingDocumentId;

  const DocumentFormScreen({
    super.key,
    this.existingDocumentId,
  });

  @override
  ConsumerState<DocumentFormScreen> createState() => _DocumentFormScreenState();
}

class _DocumentFormScreenState extends ConsumerState<DocumentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedTypeId;
  String? _selectedVehicleId; // null = Driver / Personal
  final _titleController = TextEditingController();
  final _docNumberController = TextEditingController();
  final _authorityController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _issueDate;
  DateTime? _expiryDate;
  bool _noExpiry = false;

  final Set<int> _selectedReminderDays = {30, 15, 7, 1};
  bool _isQuickShow = false;

  // New photos to attach
  Uint8List? _frontPhotoBytes;
  String? _frontPhotoName;
  Uint8List? _backPhotoBytes;
  String? _backPhotoName;

  // Existing files when editing
  List<DocumentFileData> _existingFiles = [];
  final List<String> _fileIdsToDelete = [];

  bool _isLoading = false;
  bool _isInitialLoad = true;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _docNumberController.dispose();
    _authorityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (widget.existingDocumentId != null) {
      final repo = ref.read(documentsRepositoryProvider);
      final docDetails = await repo.getDocumentById(widget.existingDocumentId!);
      if (docDetails != null && mounted) {
        final doc = docDetails.document;
        setState(() {
          _selectedTypeId = doc.documentTypeId;
          _selectedVehicleId = doc.vehicleId;
          _titleController.text = doc.title;
          _docNumberController.text = doc.documentNumber ?? '';
          _authorityController.text = doc.issuingAuthority ?? '';
          _notesController.text = doc.notes ?? '';
          _issueDate = doc.issueDate;
          _expiryDate = doc.expiryDate;
          _noExpiry = doc.expiryDate == null;
          _isQuickShow = doc.isQuickShow;
          _existingFiles = docDetails.files;

          _selectedReminderDays.clear();
          _selectedReminderDays.addAll(
            doc.reminderDaysBefore
                .split(',')
                .map((s) => int.tryParse(s.trim()))
                .whereType<int>(),
          );
          if (_selectedReminderDays.isEmpty) {
            _selectedReminderDays.addAll([30, 15, 7, 1]);
          }
        });
      }
    } else {
      // Default to selected vehicle if any
      final currentVehicle = ref.read(currentVehicleProvider);
      _selectedVehicleId = currentVehicle?.id;
    }

    if (mounted) {
      setState(() => _isInitialLoad = false);
    }
  }

  Future<void> _pickImage({
    required bool isFront,
    required ImageSource source,
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          if (isFront) {
            _frontPhotoBytes = bytes;
            _frontPhotoName = picked.name;
          } else {
            _backPhotoBytes = bytes;
            _backPhotoName = picked.name;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e')),
        );
      }
    }
  }

  void _showImagePickerSheet({required bool isFront}) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take Photo with Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(isFront: isFront, source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(isFront: isFront, source: ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Document Type')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(documentsRepositoryProvider);
      final newAttachments = <DocumentFileAttachment>[];

      if (_frontPhotoBytes != null) {
        newAttachments.add(
          DocumentFileAttachment(
            rawBytes: _frontPhotoBytes!,
            fileName: _frontPhotoName ?? 'front_side.jpg',
            mimeType: 'image/jpeg',
            pageNumber: 1,
          ),
        );
      }

      if (_backPhotoBytes != null) {
        newAttachments.add(
          DocumentFileAttachment(
            rawBytes: _backPhotoBytes!,
            fileName: _backPhotoName ?? 'back_side.jpg',
            mimeType: 'image/jpeg',
            pageNumber: 2,
          ),
        );
      }

      final reminderDaysString = _selectedReminderDays.toList()..sort((a, b) => b.compareTo(a));

      await repo.saveDocument(
        id: widget.existingDocumentId,
        vehicleId: _selectedVehicleId,
        documentTypeId: _selectedTypeId!,
        title: _titleController.text.trim(),
        documentNumber: _docNumberController.text.trim().isEmpty
            ? null
            : _docNumberController.text.trim(),
        issueDate: _issueDate,
        expiryDate: _noExpiry ? null : _expiryDate,
        issuingAuthority: _authorityController.text.trim().isEmpty
            ? null
            : _authorityController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        isQuickShow: _isQuickShow,
        reminderDaysBefore: reminderDaysString.join(','),
        newAttachments: newAttachments,
        fileIdsToDelete: _fileIdsToDelete,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingDocumentId != null
                  ? 'Document updated successfully'
                  : 'Document encrypted and saved to vault',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving document: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vehicles = ref.watch(activeVehiclesStreamProvider).asData?.value ?? [];
    final docTypes = ref.watch(documentTypesProvider).asData?.value ?? [];
    final dateFormat = DateFormat.yMMMMd();

    if (_isInitialLoad) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Auto-select first doc type if none selected
    if (_selectedTypeId == null && docTypes.isNotEmpty) {
      _selectedTypeId = docTypes.first.id;
      if (_titleController.text.isEmpty) {
        _titleController.text = docTypes.first.name;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingDocumentId != null ? 'Edit Document' : 'Add Document',
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Document Type Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedTypeId,
              decoration: const InputDecoration(
                labelText: 'Document Type *',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              items: docTypes.map((t) {
                return DropdownMenuItem(
                  value: t.id,
                  child: Text(t.name),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedTypeId = val;
                    final selected = docTypes.firstWhere((t) => t.id == val);
                    if (_titleController.text.isEmpty ||
                        docTypes.any((t) => t.name == _titleController.text)) {
                      _titleController.text = selected.name;
                    }
                    if (!selected.isVehicleSpecific) {
                      _selectedVehicleId = null; // Driver doc
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Vehicle Selector Dropdown
            DropdownButtonFormField<String?>(
              initialValue: _selectedVehicleId,
              decoration: const InputDecoration(
                labelText: 'Linked To',
                prefixIcon: Icon(Icons.directions_car_outlined),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Driver / Personal (No Vehicle)'),
                    ],
                  ),
                ),
                ...vehicles.map((v) {
                  return DropdownMenuItem<String?>(
                    value: v.id,
                    child: Text('${v.name} (${v.plateNumber})'),
                  );
                }),
              ],
              onChanged: (val) => setState(() => _selectedVehicleId = val),
            ),
            const SizedBox(height: 16),

            // Document Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Document Title *',
                hintText: 'e.g. Driving License, Tax Token 2026',
                prefixIcon: Icon(Icons.title_rounded),
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Document Number & Issuing Authority in Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _docNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Document Number',
                      hintText: 'e.g. DL-192837',
                      prefixIcon: Icon(Icons.tag_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _authorityController,
                    decoration: const InputDecoration(
                      labelText: 'Issuing Authority',
                      hintText: 'e.g. BRTA, DMV',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Issue Date & Expiry Date Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dates & Validity',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Issue Date Picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Issue Date'),
                      subtitle: Text(
                        _issueDate != null
                            ? dateFormat.format(_issueDate!)
                            : 'Not set (Optional)',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_issueDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => setState(() => _issueDate = null),
                            ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _issueDate ?? DateTime.now(),
                                firstDate: DateTime(1980),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _issueDate = picked);
                              }
                            },
                            child: const Text('Select'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // No Expiry Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Does Not Expire (Lifetime)'),
                      value: _noExpiry,
                      onChanged: (val) {
                        setState(() {
                          _noExpiry = val;
                          if (val) _expiryDate = null;
                        });
                      },
                    ),
                    if (!_noExpiry) ...[
                      const Divider(),
                      // Expiry Date Picker
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_busy_rounded),
                        title: const Text('Expiry Date *'),
                        subtitle: Text(
                          _expiryDate != null
                              ? dateFormat.format(_expiryDate!)
                              : 'Select expiry date',
                          style: TextStyle(
                            color: _expiryDate == null
                                ? colorScheme.error
                                : colorScheme.onSurface,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _expiryDate ??
                                  DateTime.now().add(const Duration(days: 365)),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2050),
                            );
                            if (picked != null) {
                              setState(() => _expiryDate = picked);
                            }
                          },
                          child: const Text('Select'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Reminder Schedule chips
                      Text(
                        'Remind me before expiry:',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [30, 15, 7, 1].map((days) {
                          final isSelected =
                              _selectedReminderDays.contains(days);
                          return FilterChip(
                            label: Text('$days days'),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedReminderDays.add(days);
                                } else {
                                  _selectedReminderDays.remove(days);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Encrypted Document Photos Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_rounded, size: 18, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Encrypted Document Photos',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Photos are encrypted with AES-256-GCM before saving to private storage.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Front Photo Card
                        Expanded(
                          child: _buildPhotoSlot(
                            label: 'Front Side',
                            newBytes: _frontPhotoBytes,
                            existingFile: _existingFiles.isNotEmpty
                                ? _existingFiles.first
                                : null,
                            onPick: () => _showImagePickerSheet(isFront: true),
                            onRemove: () {
                              setState(() {
                                if (_frontPhotoBytes != null) {
                                  _frontPhotoBytes = null;
                                  _frontPhotoName = null;
                                } else if (_existingFiles.isNotEmpty) {
                                  _fileIdsToDelete.add(_existingFiles.first.id);
                                  _existingFiles = List.from(_existingFiles)..removeAt(0);
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Back Photo Card
                        Expanded(
                          child: _buildPhotoSlot(
                            label: 'Back Side',
                            newBytes: _backPhotoBytes,
                            existingFile: _existingFiles.length > 1
                                ? _existingFiles[1]
                                : null,
                            onPick: () => _showImagePickerSheet(isFront: false),
                            onRemove: () {
                              setState(() {
                                if (_backPhotoBytes != null) {
                                  _backPhotoBytes = null;
                                  _backPhotoName = null;
                                } else if (_existingFiles.length > 1) {
                                  _fileIdsToDelete.add(_existingFiles[1].id);
                                  _existingFiles = List.from(_existingFiles)..removeAt(1);
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick Show Switch Card
            Card(
              child: SwitchListTile(
                secondary: Icon(
                  Icons.shield_rounded,
                  color: _isQuickShow ? colorScheme.primary : null,
                ),
                title: const Text('Traffic Police Quick Show'),
                subtitle: const Text(
                  'Make accessible in high-contrast full-screen police verification mode',
                ),
                value: _isQuickShow,
                onChanged: (val) => setState(() => _isQuickShow = val),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Any extra details, renewal instructions, policy agent...',
                prefixIcon: Icon(Icons.notes_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            FilledButton.icon(
              onPressed: _isLoading ? null : _save,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _isLoading
                    ? 'Encrypting & Saving...'
                    : widget.existingDocumentId != null
                        ? 'Update Document'
                        : 'Save Encrypted Document',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSlot({
    required String label,
    required Uint8List? newBytes,
    required DocumentFileData? existingFile,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasPhoto = newBytes != null || existingFile != null;

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPhoto ? colorScheme.primary : colorScheme.outlineVariant,
          width: hasPhoto ? 1.5 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (newBytes != null)
              Image.memory(newBytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
            else if (existingFile != null)
              FutureBuilder<Uint8List>(
                future: ref.read(documentsRepositoryProvider).decryptFile(existingFile.filePath),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              )
            else
              InkWell(
                onTap: onPick,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 32, color: colorScheme.primary),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tap to add',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Top overlay chip with label if photo is attached
            if (hasPhoto) ...[
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.65),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
                    onPressed: onRemove,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
