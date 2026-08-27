import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/data/sample_data.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/api_models.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/home_provider.dart';
import '../../core/providers/pravachan_provider.dart';
import '../../core/utils/auth_gate.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/language_toggle.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/widgets/network_error_widget.dart';
import '../bhajan/bhajan_screen.dart';
import '../books/books_screen.dart';
import '../events/events_screen.dart';
import '../gallery/gallery_screen.dart';
import '../pravachan/pravachan_detail_screen.dart';
import '../pravachan/pravachan_screen.dart';
import '../conference/conference_screen.dart';
import 'notification_screen.dart';
import 'notification_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _sankalpDone = false;
  late PageController _thoughtController;
  Timer? _thoughtTimer;
  int _currentThoughtPage = 0;

  @override
  void initState() {
    super.initState();
    _loadSankalp();
    _thoughtController = PageController(initialPage: 0);
    _startThoughtTimer();
  }

  @override
  void dispose() {
    _thoughtTimer?.cancel();
    _thoughtController.dispose();
    super.dispose();
  }

  void _startThoughtTimer() {
    _thoughtTimer?.cancel();
    _thoughtTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final homeData = ref.read(homeProvider).data;
      final thoughtsCount = homeData?.thoughts.length ?? 0;
      if (thoughtsCount > 1) {
        _currentThoughtPage++;
        if (_currentThoughtPage >= thoughtsCount) {
          _currentThoughtPage = 0;
        }
        if (_thoughtController.hasClients) {
          _thoughtController.animateToPage(
            _currentThoughtPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    });
  }

  String get _todayKey =>
      'sankalp_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';

  Future<void> _loadSankalp() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _sankalpDone = prefs.getBool(_todayKey) ?? false);
  }

  Future<void> _markSankalp() async {
    // Restriction removed: Guest users can now also mark sankalp as done
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_todayKey, true);
    if (!mounted) return;
    setState(() => _sankalpDone = true);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';

    final homeState = ref.watch(homeProvider);
    
    // Show full screen error if API fails and we have no cached data
    if (homeState.error != null && homeState.data == null) {
      return Scaffold(
        backgroundColor: AppColors.ivory,
        body: NetworkErrorWidget(
          message: homeState.error,
          onRetry: () => ref.read(homeProvider.notifier).load(),
        ),
      );
    }

    final homeData = homeState.data;
    // FAIL-SAFE logic: Use API data if available, otherwise fallback gracefully to local data
    final hasApiData = homeData != null && homeData.thoughts.isNotEmpty;
    final thoughts = hasApiData ? homeData.thoughts : [];
    final profile = homeData?.profile;

    final quote = hasApiData
        ? thoughts[_currentThoughtPage % thoughts.length].getText(isHindi)
        : (isHindi ? SampleData.todaysQuote.textHi : SampleData.todaysQuote.textEn);
    final quoteSource = (profile?.getPolitician(isHindi).isNotEmpty == true)
        ? profile!.getPolitician(isHindi)
        : (profile?.getName(isHindi).isNotEmpty == true)
            ? profile!.getName(isHindi)
            : SampleData.todaysQuote.source;

    final heroImage = homeData?.banners.isNotEmpty == true
        ? homeData!.banners.first.image ?? SampleData.heroImage
        : SampleData.heroImage;
    final portraitImage = profile?.photo ?? SampleData.portrait;

    final dateText = DateFormat.yMMMMEEEEd(isHindi ? 'hi' : 'en').format(
      DateTime.now(),
    );

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: RefreshIndicator(
        onRefresh: () => ref.read(homeProvider.notifier).load(),
        color: AppColors.maroon,
        child: Stack(
          children: [
            // BOTTOM LAYER: Content
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  primary: true,
                  backgroundColor: AppColors.maroon,
                  elevation: 0,
                  toolbarHeight: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppNetworkImage(url: heroImage),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black45, Colors.transparent, AppColors.maroonDark],
                              stops: [0.0, 0.35, 1.0],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 18,
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.gold, width: 2),
                                ),
                                child: ClipOval(
                                  child: AppNetworkImage(
                                    url: portraitImage,
                                    width: 60,
                                    height: 60,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${context.tr('namaste')}, ${(user?.name != null && user!.name != 'Guest') ? user.name.split(' ').first : (user?.phone ?? context.tr('guest'))} 🙏',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: AppColors.goldLight, 
                                            fontWeight: FontWeight.bold,
                                            fontSize: 19, // Uniform size for both languages
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateText,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: AppColors.onDark.withValues(alpha: 0.85)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    _buildContentSection(isHindi, quote, quoteSource, homeData),
                  ]),
                ),
              ],
            ),

            // TOP LAYER: Language Toggle
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 16,
              child: Row(
                children: [
                  if (homeData != null && homeData.notifications.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                      onPressed: () => _push(const NotificationScreen()),
                    ),
                  const LanguageToggle(onDark: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(bool isHindi, String quoteText, String quoteSource, ApiHomeData? homeData) {
    final profile = homeData?.profile;
    final thoughts = homeData?.thoughts ?? [];
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Column(
      children: [
        // 1. Today's Thoughts Slider (Responsive Height + Auto Slide + Fallback)
        if (thoughts.isNotEmpty)
          Column(
            children: [
              SizedBox(
                height: isTablet ? 280 : 250,
                child: PageView.builder(
                  controller: _thoughtController,
                  itemCount: thoughts.length,
                  onPageChanged: (index) {
                    setState(() => _currentThoughtPage = index);
                    _startThoughtTimer();
                  },
                  itemBuilder: (context, index) {
                    final thought = thoughts[index];
                    return Padding(
                      padding: EdgeInsets.fromLTRB(20, size.height * 0.02, 20, 0),
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 30 : 22),
                        decoration: BoxDecoration(
                          gradient: AppColors.maroonGradient,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.format_quote, color: AppColors.goldLight),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('todaysQuote'),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.goldLight,
                                    fontSize: isTablet ? 20 : 16,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isTablet ? 18 : 12),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Text(
                                  thought.getText(isHindi),
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.onDark, 
                                    height: 1.65,
                                    fontSize: isTablet ? 18 : 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '— ${thought.getName(isHindi).isNotEmpty ? thought.getName(isHindi) : quoteSource}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.goldLight,
                                fontWeight: FontWeight.bold,
                                fontSize: isTablet ? 16 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Page Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  thoughts.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentThoughtPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentThoughtPage == index ? AppColors.maroon : AppColors.gold.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          // Professional Fallback Quote Box if API is empty
          Padding(
            padding: EdgeInsets.fromLTRB(20, size.height * 0.02, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppColors.maroonGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.format_quote, color: AppColors.goldLight),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('todaysQuote'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.goldLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    quoteText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.onDark, height: 1.65),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '— $quoteSource',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.goldLight),
                  ),
                ],
              ),
            ),
          ),

        // 2. About Swami Ji
        SectionHeader(title: (profile?.getName(isHindi).isNotEmpty == true) ? profile!.getName(isHindi) : context.tr('aboutSwamiTitle')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            child: Column(
              children: [
                AppNetworkImage(url: profile?.photo ?? SampleData.aboutImage, height: 200, width: double.infinity),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (profile?.getPolitician(isHindi).isNotEmpty == true) ? profile!.getPolitician(isHindi) : context.tr('aboutSwamiTagline'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.maroon, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        (profile?.getDescription(isHindi).isNotEmpty == true) ? profile!.getDescription(isHindi) : context.tr('aboutSwamiBody'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ImpactBadge(label: context.tr('impactKanyaVivah'), icon: Icons.favorite),
                          _ImpactBadge(label: context.tr('impactGangaSeva'), icon: Icons.water_drop),
                          _ImpactBadge(label: context.tr('impactTempleRenovation'), icon: Icons.temple_hindu),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Seva Work
        SectionHeader(title: context.tr('ourSevaWork')),
        SizedBox(
          height: isTablet ? 240 : 200,
          child: Builder(
            builder: (context) {
              final notifications = homeData?.notifications ?? [];
              final displayList = notifications.isNotEmpty ? notifications : SampleData.sevaKaryas;
              
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: displayList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  final item = displayList[i];
                  final String title;
                  final String desc;
                  final String imageUrl;

                  if (item is ApiNotification) {
                    title = item.getName(isHindi);
                    desc = item.getTitle(isHindi); // short description
                    imageUrl = item.image ?? SampleData.heroImage;
                  } else {
                    final s = item as SevaKarya;
                    title = isHindi ? s.titleHi : s.titleEn;
                    desc = isHindi ? s.descHi : s.descEn;
                    imageUrl = s.imageUrl;
                  }

                  return SizedBox(
                    width: isTablet ? 300 : 240,
                    child: GestureDetector(
                      onTap: () {
                        if (item is ApiNotification) {
                          _push(NotificationDetailScreen(notification: item));
                        }
                      },
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                AppNetworkImage(url: imageUrl, height: isTablet ? 140 : 110, width: double.infinity),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(10, 16, 10, 6),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Colors.transparent, AppColors.maroonDark],
                                      ),
                                    ),
                                    child: Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.onDark, 
                                        fontWeight: FontWeight.w700, 
                                        fontSize: isTablet ? 16 : 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  desc, 
                                  maxLines: 3, 
                                  overflow: TextOverflow.ellipsis, 
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: isTablet ? 14 : 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          ),
        ),

        // 4. Quick Actions
        SectionHeader(title: context.tr('quickActions')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _QuickAction(icon: Icons.photo_library_outlined, label: context.tr('gallery'), onTap: () => _push(const GalleryScreen())),
              _QuickAction(icon: Icons.event_outlined, label: context.tr('events'), onTap: () => _push(const EventsScreen())),
              _QuickAction(icon: Icons.menu_book_outlined, label: context.tr('books'), onTap: () => _push(const BooksScreen())),
              _QuickAction(icon: Icons.music_note_outlined, label: context.tr('bhajan'), onTap: () {
                // Ideally this should switch to the Bhajan tab in MainShell
                // For now, navigating directly is consistent with other quick actions
                _push(const BhajanScreen());
              }),
            ],
          ),
        ),

        // 5. Daily Sankalp
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.sandalwood, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.self_improvement, color: AppColors.maroon, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('dailySankalp'), style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(_sankalpDone ? context.tr('sankalpDone') : context.tr('sankalpMantra'), style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                    ),
                  if (!_sankalpDone)
                    TextButton(onPressed: _markSankalp, child: Text(context.tr('markDone')))
                  else
                    const Icon(Icons.check_circle, color: AppColors.success),
                ],
              ),
            ),
          ),
        ),

        // 6. Aarti Timings
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.sandalwood, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.brightness_5_outlined, color: AppColors.saffron),
                const SizedBox(width: 10),
                Expanded(child: Text('${context.tr('morningAarti')} — 6:00 AM', style: Theme.of(context).textTheme.bodyMedium)),
                const Icon(Icons.nightlight_outlined, color: AppColors.maroon),
                const SizedBox(width: 10),
                Text('${context.tr('eveningAarti')} — 7:00 PM', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),

        // 7. Live Satsang
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: GestureDetector(
            onTap: () async {
              if (await ensureSignedInWithRef(context, ref) && mounted) _push(const JoinConferenceScreen());
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.maroonGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.25), shape: BoxShape.circle),
                    child: const Icon(Icons.live_tv, color: AppColors.goldLight, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(context.tr('liveSatsang'), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.onDark))),
                  const Icon(Icons.chevron_right, color: AppColors.goldLight),
                ],
              ),
            ),
          ),
        ),

        // 8. Discourses
        SectionHeader(
          title: context.tr('latestPravachan'),
          actionLabel: context.tr('viewAll'),
          onAction: () => _push(const PravachanScreen(standalone: true)),
        ),
        SizedBox(
          height: isTablet ? 260 : 218,
          child: Consumer(
            builder: (context, ref, _) {
              final pravachanState = ref.watch(pravachanProvider);
              final hasApiData = pravachanState.items.isNotEmpty;
              final items = hasApiData ? pravachanState.items : SampleData.pravachans;
              
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  final p = items[i];
                  return GestureDetector(
                    onTap: () => _push(PravachanDetailScreen(pravachan: p)),
                    child: SizedBox(
                      width: isTablet ? 280 : 230,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppNetworkImage(
                              url: p.imageUrl, 
                              height: isTablet ? 150 : 120, 
                              width: double.infinity,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isHindi ? p.titleHi : p.titleEn,
                                    maxLines: 2, 
                                    overflow: TextOverflow.ellipsis, 
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontSize: isTablet ? 16 : 14,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule, size: 15, color: AppColors.gold),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${p.durationMin} ${context.tr('minutes')}', 
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontSize: isTablet ? 14 : 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          ),
        ),

        // 9. Upcoming Events
        SectionHeader(
          title: context.tr('upcomingEvents'),
          actionLabel: context.tr('viewAll'),
          onAction: () => _push(const EventsScreen()),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 50),
          child: Column(
            children: (homeData?.announcements.isNotEmpty == true)
                ? homeData!.announcements.take(3).map((a) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: GestureDetector(
                        onTap: () => _push(NotificationDetailScreen(
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
                        )),
                        child: Stack(
                          children: [
                            Card(
                              clipBehavior: Clip.antiAlias,
                              child: Row(
                                children: [
                                  AppNetworkImage(url: a.image ?? SampleData.heroImage, width: 96, height: 96),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(a.getTitle(isHindi), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                                          const SizedBox(height: 4),
                                          if (a.date != null)
                                            Text(
                                              (a.dateTo != null && a.dateTo != a.date)
                                                  ? '${a.date} — ${a.dateTo}'
                                                  : a.date!,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: AppColors.saffron,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          const SizedBox(height: 2),
                                          Text(a.getDescription(isHindi), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.chevron_right, color: AppColors.gold)),
                                ],
                              ),
                            ),
                            // "New" Badge for API announcements
                            if (a.isNew)
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    context.tr('newBadge'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList()
                : SampleData.events.take(2).map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Row(
                          children: [
                            AppNetworkImage(url: e.imageUrl, width: 96, height: 96),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isHindi ? e.titleHi : e.titleEn, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 4),
                                    Text(DateFormat.yMMMd(isHindi ? 'hi' : 'en').format(e.date), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.saffron, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(isHindi ? e.venueHi : e.venueEn, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
                                  ],
                                ),
                              ),
                            ),
                            const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.chevron_right, color: AppColors.gold)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
          ),
        ),
      ],
    );
  }

  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

class _ImpactBadge extends StatelessWidget {
  const _ImpactBadge({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.sandalwood,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.maroon),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.maroonDark)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.maroon.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: AppColors.maroon, size: 27),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
