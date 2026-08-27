import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/sample_data.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/pravachan_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import 'pravachan_detail_screen.dart';

class PravachanScreen extends ConsumerWidget {
  const PravachanScreen({super.key, this.standalone = false});

  /// When opened from Home's "view all" (outside the bottom-nav shell)
  /// we show a back button; inside the shell we don't.
  final bool standalone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';
    final pravachanState = ref.watch(pravachanProvider);
    final items = pravachanState.items.isNotEmpty 
        ? pravachanState.items 
        : SampleData.pravachans;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('allPravachan')),
        automaticallyImplyLeading: standalone,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final p = items[i];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PravachanDetailScreen(pravachan: p))),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      AppNetworkImage(
                          url: p.imageUrl,
                          height: 170,
                          width: double.infinity),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.maroonDark
                                .withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.play_arrow,
                                  size: 16, color: AppColors.goldLight),
                              const SizedBox(width: 4),
                              Text(
                                '${p.durationMin} ${context.tr('minutes')}',
                                style: const TextStyle(
                                    color: AppColors.onDark, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isHindi ? p.titleHi : p.titleEn,
                            style:
                                Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(
                          isHindi ? p.descriptionHi : p.descriptionEn,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat.yMMMd(isHindi ? 'hi' : 'en')
                              .format(p.date),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w600),
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
