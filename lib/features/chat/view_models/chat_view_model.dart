import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/chat/chat_service.dart';
import '../../../core/chat/chat_models.dart';
import '../../../core/providers/providers.dart';

class ChatRoomListState {
  final List<Channel> channels;
  final List<Channel> members;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  ChatRoomListState({
    this.channels = const [],
    this.members = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  List<Channel> get filteredChannels {
    if (searchQuery.isEmpty) return channels;
    return channels
        .where((c) => c.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  List<Channel> get filteredMembers {
    if (searchQuery.isEmpty) return members;
    return members
        .where((m) => m.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  ChatRoomListState copyWith({
    List<Channel>? channels,
    List<Channel>? members,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return ChatRoomListState(
      channels: channels ?? this.channels,
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ChatViewModel extends Notifier<ChatRoomListState> {
  Timer? _refreshTimer;

  @override
  ChatRoomListState build() {
    // Watch auth state - when user logs in or bootstrap completes, refresh list
    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.signedIn) {
        _init();
      } else if (next.status == AuthStatus.signedOut) {
        _refreshTimer?.cancel();
        state = ChatRoomListState(isLoading: false);
      }
    });

    // Start auto-refresh polling (every 30 seconds) to make user list live
    _startPolling();

    // Initial trigger
    Future.microtask(() => _init());
    
    ref.onDispose(() => _refreshTimer?.cancel());
    
    return ChatRoomListState(isLoading: true);
  }

  void _startPolling() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.signedIn) {
        refresh();
      }
    });
  }

  Future<void> _init() async {
    // If already loading and we already have some data, don't show full screen spinner
    final isBackgroundRefresh = state.isLoading && (state.channels.isNotEmpty || state.members.isNotEmpty);
    if (!isBackgroundRefresh) {
      state = state.copyWith(isLoading: true);
    }
    try {
      final service = ref.read(chatServiceProvider);
      
      // Fetch active channels, and users (non-subscribers)
      final results = await Future.wait([
        service.channels(),
        service.members(isSubscriber: false), // Swami Ji sees regular users
      ]);
      
      final List<Channel> activeChannels = results[0];
      final List<Channel> allUsers = results[1];
      
      // Map active channels by targetId for quick lookup
      final Map<String, Channel> activeMap = {
        for (var c in activeChannels) 
          if (c.targetId != null) c.targetId!: c
      };

      // 1. VERTICAL LIST: Recent Messages
      // Contains active conversations + users who don't have an active conversation yet
      final List<Channel> mergedChannels = [];
      mergedChannels.addAll(activeChannels);

      for (var u in allUsers) {
        if (u.targetId != null && !activeMap.containsKey(u.targetId)) {
          mergedChannels.add(u); // These show "Tap to chat"
        }
      }

      // 2. HORIZONTAL LIST: Community Members
      // For now, show the same users in the horizontal list too (or filter differently if needed)
      final List<Channel> horizontalMembers = allUsers;

      state = state.copyWith(
        channels: mergedChannels,
        members: horizontalMembers,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      String errorMessage = e.toString();
      if (e.toString().contains('SocketException') || e.toString().contains('host lookup')) {
        errorMessage = 'Internet connection failed. Please check your network.';
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<void> refresh() => _init();

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void signOut() {
    ref.read(authProvider.notifier).signOut();
  }
}

final chatViewModelProvider = NotifierProvider<ChatViewModel, ChatRoomListState>(() {
  return ChatViewModel();
});
