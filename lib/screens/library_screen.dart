import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/library_models.dart';
import '../providers/library_controller.dart';
import '../widgets/empty_state.dart';
import '../widgets/ink_panel.dart';
import 'book_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LibraryController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_searchController.text != controller.filter) {
      _searchController.value = TextEditingValue(
        text: controller.filter,
        selection: TextSelection.collapsed(offset: controller.filter.length),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadBooks,
      color: scheme.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        children: [
          // --- Search panel ---
          InkPanel(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: controller.setFilter,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search by title, series, or author',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.library_books_outlined,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${controller.filteredItems.length} of ${controller.items.length} books',
                      style: theme.textTheme.bodySmall,
                    ),
                    const Spacer(),
                    if (controller.isLoading)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: scheme.primary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // --- Error ---
          if (controller.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: scheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // --- Loading spinner ---
          if (controller.isLoading && controller.items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          // --- Empty ---
          else if (controller.filteredItems.isEmpty)
            const SizedBox(
              height: 320,
              child: EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No books match',
                message:
                    'Try a broader title or author search, or pull down to refresh.',
              ),
            )
          // --- Book cards ---
          else
            ...controller.filteredItems.map(
              (book) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BookCard(book: book),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Book card
// ---------------------------------------------------------------------------

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book});

  final BookListItem book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BookDetailScreen(bookId: book.id),
          ),
        );
      },
      child: InkPanel(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book icon / format badge
            Container(
              width: 44,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _formatIcon(book.fileFormat),
                    size: 20,
                    color: scheme.primary,
                  ),
                  if (book.fileFormat?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      book.fileFormat!.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Book info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  if (book.authorName?.isNotEmpty == true ||
                      book.seriesName?.isNotEmpty == true)
                    Text(
                      [
                        if (book.authorName?.isNotEmpty == true)
                          book.authorName,
                        if (book.seriesName?.isNotEmpty == true)
                          book.seriesName,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _StatusChip(status: book.status),
                      const SizedBox(width: 8),
                      if (book.publishedDate?.isNotEmpty == true)
                        Text(
                          book.publishedDate!,
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Passage count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    '${book.passageCount}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    'passages',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _formatIcon(String? format) {
    return switch (format?.toLowerCase()) {
      'epub' => Icons.auto_stories,
      'pdf' => Icons.picture_as_pdf,
      'txt' => Icons.description,
      _ => Icons.menu_book,
    };
  }
}

// ---------------------------------------------------------------------------
// Status chip
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (color, bgColor) = switch (status.toLowerCase()) {
      'indexed' ||
      'complete' ||
      'ready' => (scheme.primary, scheme.primaryContainer),
      'processing' ||
      'pending' => (scheme.secondary, scheme.secondaryContainer),
      'error' || 'failed' => (scheme.error, scheme.errorContainer),
      _ => (scheme.onSurfaceVariant, scheme.surfaceContainerLow),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        status,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
