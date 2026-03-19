import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/library_models.dart';
import '../providers/auth_controller.dart';
import '../services/inkquery_api_client.dart';
import '../widgets/ink_panel.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({required this.bookId, super.key});

  final int bookId;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late Future<BookDetail> _future;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    final api = context.read<InkqueryApiClient>();
    _future = auth.authorizedRequest(
      (session) => api.getBookDetail(
        baseUrl: session.account.serverUrl,
        accessToken: session.tokens.accessToken,
        bookId: widget.bookId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Book'),
      ),
      body: FutureBuilder<BookDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: scheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Loading book details...',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 28,
                        color: scheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load book',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${snapshot.error}',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final book = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // --- Hero header ---
              _BookHeroHeader(book: book),

              const SizedBox(height: 16),

              // --- Metadata chips ---
              _BookMetaChips(book: book),

              const SizedBox(height: 20),

              // --- Sample passages section ---
              if (book.samplePassages.isNotEmpty) ...[
                _SectionHeader(
                  icon: Icons.format_quote_rounded,
                  label: 'Sample passages',
                  count: book.samplePassages.length,
                ),
                const SizedBox(height: 10),
                ...book.samplePassages.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PassageCard(
                      passage: entry.value,
                      index: entry.key + 1,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 48),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        size: 36,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No sample passages available',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero header — book icon, title, author, series
// ---------------------------------------------------------------------------

class _BookHeroHeader extends StatelessWidget {
  const _BookHeroHeader({required this.book});

  final BookDetail book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final subtitle = [
      if (book.authorName?.isNotEmpty == true) book.authorName,
      if (book.seriesName?.isNotEmpty == true) book.seriesName,
    ].join(' · ');

    return InkPanel(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book format icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _formatIcon(book.fileFormat),
              size: 26,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title, style: theme.textTheme.headlineMedium),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (book.publishedDate?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(book.publishedDate!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _formatIcon(String? format) {
    return switch (format?.toLowerCase()) {
      'epub' => Icons.auto_stories_rounded,
      'pdf' => Icons.picture_as_pdf_rounded,
      'mobi' => Icons.phone_android_rounded,
      'txt' || 'text' => Icons.description_rounded,
      'html' || 'htm' => Icons.language_rounded,
      _ => Icons.menu_book_rounded,
    };
  }
}

// ---------------------------------------------------------------------------
// Metadata chips — format, status, passage count, source
// ---------------------------------------------------------------------------

class _BookMetaChips extends StatelessWidget {
  const _BookMetaChips({required this.book});

  final BookDetail book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (statusColor, statusBg) = _statusColors(book.status, scheme);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Status chip
        _MetaChip(
          icon: Icons.circle,
          iconSize: 8,
          iconColor: statusColor,
          label: book.status,
          bgColor: statusBg,
          textColor: statusColor,
        ),
        // Passage count
        _MetaChip(
          icon: Icons.format_quote_rounded,
          iconSize: 14,
          iconColor: scheme.primary,
          label: '${book.passageCount} passages',
          bgColor: scheme.primaryContainer,
          textColor: scheme.primary,
        ),
        // Format
        if (book.fileFormat?.isNotEmpty == true)
          _MetaChip(
            icon: _formatIcon(book.fileFormat),
            iconSize: 14,
            iconColor: scheme.onSurfaceVariant,
            label: book.fileFormat!.toUpperCase(),
            bgColor: scheme.surfaceContainerLow,
            textColor: scheme.onSurfaceVariant,
          ),
        // Source
        if (book.sourcePath?.isNotEmpty == true)
          _MetaChip(
            icon: Icons.folder_outlined,
            iconSize: 14,
            iconColor: scheme.onSurfaceVariant,
            label: _shortenPath(book.sourcePath!),
            bgColor: scheme.surfaceContainerLow,
            textColor: scheme.onSurfaceVariant,
          ),
      ],
    );
  }

  (Color, Color) _statusColors(String status, ColorScheme scheme) {
    return switch (status.toLowerCase()) {
      'ready' || 'indexed' => (scheme.primary, scheme.primaryContainer),
      'processing' ||
      'pending' => (scheme.secondary, scheme.secondaryContainer),
      'error' || 'failed' => (scheme.error, scheme.errorContainer),
      _ => (scheme.onSurfaceVariant, scheme.surfaceContainerLow),
    };
  }

  IconData _formatIcon(String? format) {
    return switch (format?.toLowerCase()) {
      'epub' => Icons.auto_stories_rounded,
      'pdf' => Icons.picture_as_pdf_rounded,
      'mobi' => Icons.phone_android_rounded,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  String _shortenPath(String path) {
    if (path.length <= 30) return path;
    final parts = path.split('/');
    if (parts.length <= 2) return path;
    return '.../${parts.sublist(parts.length - 2).join('/')}';
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.iconSize,
    required this.iconColor,
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final String label;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label, this.count});

  final IconData icon;
  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.titleMedium),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Passage card
// ---------------------------------------------------------------------------

class _PassageCard extends StatelessWidget {
  const _PassageCard({required this.passage, required this.index});

  final SamplePassage passage;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final hasChapter = passage.chapterLabel?.isNotEmpty == true;

    return InkPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasChapter)
                  Text(
                    passage.chapterLabel!,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                if (hasChapter) const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: scheme.primary.withValues(alpha: 0.3),
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: SelectableText(
                    passage.excerpt,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.55,
                      fontStyle: FontStyle.italic,
                      color: scheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
