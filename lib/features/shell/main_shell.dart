import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/providers/home_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/connect_bottom_sheet.dart';
import '../bhajan/bhajan_screen.dart';
import '../chat/views/chat_view.dart';
import '../donation/donation_screen.dart';
import '../home/home_screen.dart';
import '../pravachan/pravachan_screen.dart';
import '../profile/profile_screen.dart';
import '../conference/conference_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const PravachanScreen(),
      const JoinConferenceScreen(),
      const ChatView(),
      const ProfileScreen(),
    ];

    final homeData = ref.watch(homeProvider).data;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index, 
        children: pages
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _index == 0 ? Padding(
        padding: const EdgeInsets.only(bottom: 70), // Avoid overlap with bottom bar
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 1. Donate FAB
            FloatingActionButton.small(
              heroTag: 'donate_fab',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DonationScreen()));
              },
              backgroundColor: AppColors.saffron,
              foregroundColor: Colors.white,
              tooltip: context.tr('donation'),
              child: const Icon(Icons.volunteer_activism),
            ),
            const SizedBox(height: 12),
            // 2. Connect FAB
            FloatingActionButton(
              heroTag: 'connect_fab',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ConnectBottomSheet(profile: homeData?.profile),
                );
              },
              backgroundColor: AppColors.maroon,
              foregroundColor: AppColors.goldLight,
              tooltip: context.tr('connect'),
              child: const Icon(Icons.link),
            ),
          ],
        ),
      ) : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.maroon,
          selectedItemColor: AppColors.goldLight,
          unselectedItemColor: const Color(0xFFBFA08E).withValues(alpha: 0.7),
          currentIndex: _index,
          onTap: (i) {
            setState(() => _index = i);
          },
          showUnselectedLabels: true,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.temple_hindu_outlined),
              activeIcon: const Icon(Icons.temple_hindu),
              label: context.tr('home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.play_circle_outline),
              activeIcon: const Icon(Icons.play_circle),
              label: context.tr('pravachan'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.groups_outlined),
              activeIcon: const Icon(Icons.groups),
              label: context.tr('liveSatsang'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.forum_outlined),
              activeIcon: const Icon(Icons.forum),
              label: context.tr('sandesh'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: context.tr('profile'),
            ),
          ],
        ),
      ),
    );
  }
}
