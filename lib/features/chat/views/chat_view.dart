import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/chat/chat_models.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../view_models/chat_view_model.dart';
import 'chat_room_view.dart';
import '../../auth/login_screen.dart';
import '../../../core/providers/providers.dart';
import '../../../core/providers/home_provider.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/widgets/network_error_widget.dart';

/// ChatView
/// -----------------------------------------------------------------------------
/// Top-level chat tab: shows the list of channels (conversations). Tapping a
/// channel opens [ChatRoomView] for that conversation.
///
/// This is the widget that `main_shell.dart` references as `const ChatView()`.
class ChatView extends ConsumerWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final signedIn = authState.status == AuthStatus.signedIn;

    if (!signedIn) {
      return Scaffold(
        backgroundColor: AppColors.ivory,
        appBar: AppBar(
          backgroundColor: AppColors.maroon,
          foregroundColor: Colors.white,
          title: Text(context.tr('sandesh'), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.forum_outlined, size: 80, color: AppColors.sandalwood),
                const SizedBox(height: 16),
                Text(
                  context.tr('chatAuthPrompt'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: AppColors.maroon, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                GoldButton(
                  label: context.tr('login'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen(inAppFlow: true)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final state = ref.watch(chatViewModelProvider);
    final vm = ref.read(chatViewModelProvider.notifier);
    final homeData = ref.watch(homeProvider).data;
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';
    
    // Correct Role logic:
    // user?.isSubscriber == true -> Swami Ji (Full List)
    // user?.isSubscriber == false -> Regular User (Direct Chat)
    final bool isSwamiJi = user?.isSubscriber ?? false;

    if (!isSwamiJi) {
      // USER VIEW: Only see Swami Ji
      final swamiProfile = homeData?.profile;
      final swamiName = swamiProfile?.getName(isHindi) ?? 'Swami Ji';
      final swamiId = swamiProfile?.id?.toString() ?? '15'; // Use dynamic ID with fallback
      final userIdInt = int.tryParse(user?.id ?? '') ?? 0;
      
      return ChatRoomView(
        channelId: userIdInt, // Room ID is now the User's own ID
        title: swamiName,
        targetId: swamiId,
        targetName: swamiName,
      );
    }

    // SWAMI JI VIEW: Show the full list of users
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.maroon,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          context.tr('sandesh'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildBody(context, ref, state, vm),
    );
  }

  Widget _buildBody(
      BuildContext context,
      WidgetRef ref,
      ChatRoomListState state,
      ChatViewModel vm,
      ) {
    if (state.isLoading && state.channels.isEmpty && state.members.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (state.error != null && state.channels.isEmpty && state.members.isEmpty) {
      return NetworkErrorWidget(
        message: state.error,
        onRetry: () => vm.refresh(),
      );
    }

    return RefreshIndicator(
      color: AppColors.maroon,
      onRefresh: () => vm.refresh(),
      child: Column(
        children: [
          // 1. PREMIUM SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: vm.updateSearch,
                decoration: InputDecoration(
                  hintText: context.tr('search'),
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                  prefixIcon: const Icon(Icons.search, size: 22, color: AppColors.maroon),
                  suffixIcon: state.searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                        onPressed: () => vm.updateSearch(''),
                      )
                    : null,
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: CustomScrollView(
              slivers: [
                // 2. COMMUNITY MEMBERS (Horizontal)
                if (state.filteredMembers.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Text(
                        'Community Members',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.maroon, fontSize: 15),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 100,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: state.filteredMembers.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, i) {
                          final m = state.filteredMembers[i];
                          return GestureDetector(
                            onTap: () {
                              final int userRoomId = int.tryParse(m.targetId ?? '') ?? m.id;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatRoomView(
                                    channelId: userRoomId,
                                    title: m.name,
                                    targetId: m.targetId,
                                    targetName: m.targetName,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: AppColors.maroon,
                                      child: Text(m.initials, style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold)),
                                    ),
                                    if (m.isOnline)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppColors.ivory, width: 2),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    m.name.split(' ').first,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // 3. ACTIVE CHATS (Vertical)
                if (state.filteredChannels.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Text(
                        'Recent Messages',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.maroon, fontSize: 15),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final channel = state.filteredChannels[i];
                        return Column(
                          children: [
                            _ChannelTile(channel: channel),
                            if (i < state.filteredChannels.length - 1)
                              const Divider(height: 1, indent: 80, color: AppColors.sandalwood),
                          ],
                        );
                      },
                      childCount: state.filteredChannels.length,
                    ),
                  ),
                ],

                if (state.filteredChannels.isEmpty && state.filteredMembers.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.forum_outlined, color: AppColors.sandalwood, size: 64),
                          const SizedBox(height: 12),
                          Text(
                            state.searchQuery.isEmpty ? context.tr('noChats') : 'No results found',
                            style: const TextStyle(color: AppColors.maroon, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({required this.channel});

  final Channel channel;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.maroon,
            child: Text(
              channel.initials,
              style: const TextStyle(
                color: AppColors.goldLight,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          if (channel.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ivory, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              channel.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.maroon,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            channel.time,
            style: const TextStyle(color: Colors.black45, fontSize: 11),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              channel.preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          if (channel.unread > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 20),
              child: Text(
                '${channel.unread}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.maroon,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        final int userRoomId = int.tryParse(channel.targetId ?? '') ?? channel.id;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatRoomView(
              channelId: userRoomId,
              title: channel.name,
              targetId: channel.targetId,
              targetName: channel.targetName,
            ),
          ),
        );
      },
    );
  }
}
