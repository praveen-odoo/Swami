import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/data/sample_data.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/auth_gate.dart';
import '../../core/models/api_models.dart';
import '../../core/providers/home_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import '../home/notification_detail_screen.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  static const _key = 'registered_events';
  Set<String> _registered = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(
        () => _registered = (prefs.getStringList(_key) ?? []).toSet());
  }

  Future<void> _register(String id) async {
    // Registration is personal -> guests must sign in first.
    if (!await ensureSignedInWithRef(context, ref)) return;
    if (!mounted) return;
    setState(() => _registered.add(id));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _registered.toList());
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = context.isHindi;
    final homeData = ref.watch(homeProvider).data;
    final announcements = homeData?.announcements ?? [];
    
    // Merge announcements and sample events
    // In a real app, you'd probably just use API data if available
    final totalCount = announcements.length + SampleData.events.length;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('events'))),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: totalCount,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          // Show API Announcements first
          if (i < announcements.length) {
            final a = announcements[i];
            return GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => NotificationDetailScreen(
                  notification: ApiNotification(
                    id: a.id,
                    nameHi: a.nameHi,
                    nameEn: a.nameEn,
                    titleHi: a.titleHi,
                    titleEn: a.titleEn,
                    descriptionHi: a.descriptionHi,
                    descriptionEn: a.descriptionEn,
                    image: a.image,
                  ),
                ),
              )),
              child: Stack(
                children: [
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (a.image != null)
                          AppNetworkImage(url: a.image!, height: 160, width: double.infinity),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.getTitle(isHindi), style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 6),
                              if (a.date != null)
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: AppColors.saffron),
                                    const SizedBox(width: 6),
                                    Text(
                                      (a.dateTo != null && a.dateTo != a.date)
                                          ? '${a.date} — ${a.dateTo}'
                                          : a.date!,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppColors.saffron,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 4),
                              Text(a.getDescription(isHindi), maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // "NEW" Badge
                  if (a.isNew)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          context.tr('newBadge'),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          // Then show sample events
          final e = SampleData.events[i - announcements.length];
          final done = _registered.contains(e.id);
          return Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AppNetworkImage(
                        url: e.imageUrl,
                        height: 160,
                        width: double.infinity),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat.d().format(e.date),
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.maroonDark,
                                  height: 1),
                            ),
                            Text(
                              DateFormat.MMM(isHindi ? 'hi' : 'en')
                                  .format(e.date),
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.maroonDark),
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
                      Text(isHindi ? e.titleHi : e.titleEn,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 16, color: AppColors.saffron),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${context.tr('venue')}: ${isHindi ? e.venueHi : e.venueEn}',
                              style:
                                  Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      done
                          ? Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: AppColors.success, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  context.tr('registered'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w700),
                                ),
                              ],
                            )
                          : SizedBox(
                              height: 44,
                              child: OutlinedButton.icon(
                                onPressed: () => _register(e.id),
                                icon: const Icon(
                                    Icons.app_registration, size: 18),
                                label: Text(context.tr('register')),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
