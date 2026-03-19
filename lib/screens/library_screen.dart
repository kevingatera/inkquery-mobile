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

    if (_searchController.text != controller.filter) {
      _searchController.value = TextEditingValue(
        text: controller.filter,
        selection: TextSelection.collapsed(offset: controller.filter.length),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadBooks,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        children: [
          InkPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Text('Browse the ingested shelf', style: theme.textTheme.titleLarge),
                TextField(
                  controller: _searchController,
                  onChanged: controller.setFilter,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search by title, series, or author',
                  ),
                ),
                Text(
                  '${controller.filteredItems.length} of ${controller.items.length} books visible',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (controller.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                controller.errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          if (controller.isLoading && controller.items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.filteredItems.isEmpty)
            const SizedBox(
              height: 420,
              child: EmptyState(
                title: 'No books match',
                message: 'Try a broader title or author search, or refresh the shelf.',
              ),
            )
          else
            ...controller.filteredItems.map((book) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BookCard(book: book),
                )),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book});

  final BookListItem book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3,
                children: [
                  Text(book.title, style: theme.textTheme.titleMedium),
                  Text(
                    [
                      if (book.authorName?.isNotEmpty == true) book.authorName,
                      if (book.seriesName?.isNotEmpty == true) book.seriesName,
                    ].join(' • '),
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    [
                      if (book.fileFormat?.isNotEmpty == true) book.fileFormat!,
                      if (book.publishedDate?.isNotEmpty == true) book.publishedDate!,
                      book.status,
                    ].join('  ·  '),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (book.sourcePath?.isNotEmpty == true)
                    Text(
                      book.sourcePath!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('${book.passageCount}', style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
