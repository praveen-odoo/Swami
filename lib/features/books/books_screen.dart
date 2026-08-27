import 'package:flutter/material.dart';

import '../../core/data/sample_data.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';

class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isHindi = context.isHindi;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('books'))),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: SampleData.books.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final b = SampleData.books[i];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppNetworkImage(
                    url: b.imageUrl,
                    width: 92,
                    height: 132,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isHindi ? b.titleHi : b.titleEn,
                            style:
                                Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(
                          isHindi ? b.summaryHi : b.summaryEn,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.auto_stories_outlined,
                                size: 15, color: AppColors.gold),
                            const SizedBox(width: 5),
                            Text('${b.pages} pp.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium),
                            const Spacer(),
                            TextButton(
                              onPressed: () =>
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                          content: Text(context
                                              .tr('comingSoon')))),
                              child: Text(context.tr('readSample')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
