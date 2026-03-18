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
    return Scaffold(
      appBar: AppBar(title: const Text('Book detail')),
      body: FutureBuilder<BookDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          final book = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              InkPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Text(book.title, style: theme.textTheme.headlineMedium),
                    Text(
                      [
                        if (book.authorName?.isNotEmpty == true) book.authorName,
                        if (book.seriesName?.isNotEmpty == true) book.seriesName,
                      ].join(' • '),
                      style: theme.textTheme.bodyMedium,
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text(book.status)),
                        Chip(label: Text('${book.passageCount} passages')),
                        if (book.fileFormat?.isNotEmpty == true) Chip(label: Text(book.fileFormat!)),
                        if (book.publishedDate?.isNotEmpty == true)
                          Chip(label: Text(book.publishedDate!)),
                      ],
                    ),
                    if (book.sourcePath?.isNotEmpty == true)
                      Text(book.sourcePath!, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ...book.samplePassages.map(
                (passage) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        Text(
                          passage.chapterLabel?.isNotEmpty == true
                              ? passage.chapterLabel!
                              : 'Sample passage',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(passage.excerpt, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
