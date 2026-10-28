import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/documents_repository.dart';
import '../domain/document_expiry_calculator.dart';
import 'providers/documents_providers.dart';

class QuickShowScreen extends ConsumerStatefulWidget {
  const QuickShowScreen({super.key});

  @override
  ConsumerState<QuickShowScreen> createState() => _QuickShowScreenState();
}

class _QuickShowScreenState extends ConsumerState<QuickShowScreen> {
  int _currentDocIndex = 0;
  int _currentPageIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quickDocsAsync = ref.watch(quickShowDocumentsProvider);

    return Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          surface: Color(0xFF121212),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Quick Show',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber, width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, color: Colors.amber, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'POLICE CHECK',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: quickDocsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          ),
          error: (err, _) => Center(
            child: Text(
              'Error loading documents: $err',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          data: (docs) {
            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.folder_off_outlined,
                          size: 48,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Quick Show Documents',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Mark your essential documents (Driving License, Registration, Tax Token, Insurance) with the "Quick Show" toggle for instant offline traffic police verification.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Back to Vault'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final currentDoc = docs[_currentDocIndex.clamp(0, docs.length - 1)];

            return Column(
              children: [
                // Header with document info and expiry badge
                _buildDocumentHeader(currentDoc),

                // Main viewer with watermark
                Expanded(
                  child: _buildImageViewer(currentDoc),
                ),

                // Bottom document switcher
                if (docs.length > 1) _buildDocumentSwitcher(docs),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDocumentHeader(DocumentWithDetails doc) {
    final expiryStatus = doc.expiryStatus;
    final (badgeColor, statusText) = switch (expiryStatus) {
      DocumentExpiryStatus.expired => (
          Colors.redAccent,
          'EXPIRED (${(doc.daysUntilExpiry ?? 0).abs()}d ago)'
        ),
      DocumentExpiryStatus.expiringSoon => (
          Colors.amber,
          'EXPIRING IN ${doc.daysUntilExpiry}d'
        ),
      DocumentExpiryStatus.valid => (
          Colors.greenAccent,
          'VALID (${doc.daysUntilExpiry}d left)'
        ),
      DocumentExpiryStatus.noExpiry => (Colors.grey, 'LIFETIME / NO EXPIRY'),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(
          bottom: BorderSide(color: Colors.white12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  doc.document.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor, width: 1),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (doc.document.documentNumber != null &&
                  doc.document.documentNumber!.isNotEmpty) ...[
                Text(
                  'No: ${doc.document.documentNumber}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                doc.vehicle != null
                    ? '${doc.vehicle!.name} (${doc.vehicle!.plateNumber})'
                    : 'Driver / Personal',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageViewer(DocumentWithDetails doc) {
    if (doc.files.isEmpty) {
      return const Center(
        child: Text(
          'No images attached to this document',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    final safePageIndex = _currentPageIndex.clamp(0, doc.files.length - 1);
    final currentFile = doc.files[safePageIndex];

    return Stack(
      alignment: Alignment.center,
      children: [
        // Decrypted image container with InteractiveViewer
        FutureBuilder<Uint8List>(
          future: ref.read(documentsRepositoryProvider).decryptFile(currentFile.filePath),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Text(
                  'Failed to decrypt image: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            return InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: Image.memory(
                  snapshot.data!,
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),

        // Translucent Watermark Overlay
        IgnorePointer(
          child: Transform.rotate(
            angle: -math.pi / 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 2,
                ),
                color: Colors.black.withValues(alpha: 0.25),
              ),
              child: Text(
                'FOR OFFICIAL VERIFICATION ONLY',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.22),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
        ),

        // Front / Back page indicator if multi-page
        if (doc.files.length > 1)
          Positioned(
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(doc.files.length, (idx) {
                  final isCurrent = idx == safePageIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _currentPageIndex = idx),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent ? Colors.amber : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        idx == 0 ? 'Front' : idx == 1 ? 'Back' : 'Page ${idx + 1}',
                        style: TextStyle(
                          color: isCurrent ? Colors.black : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentSwitcher(List<DocumentWithDetails> docs) {
    return Container(
      height: 70,
      color: const Color(0xFF1E1E1E),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: docs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final doc = docs[idx];
          final isSelected = idx == _currentDocIndex;

          return InkWell(
            onTap: () {
              setState(() {
                _currentDocIndex = idx;
                _currentPageIndex = 0;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.amber : Colors.white10,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.amber : Colors.white24,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  doc.document.title,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
