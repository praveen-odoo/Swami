import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zego_uikit/zego_uikit.dart';
import '../../../core/chat/chat_service.dart';
import '../../../core/chat/chat_models.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/zego_call_manager.dart';

class ChatRoomState {
  final List<Message> messages;
  final bool isLoading;
  final bool isSending;
  final bool isZegoReady;
  final String zegoStatus;
  final Message? replyingTo;
  final bool isRemoteTyping;
  final String? error;

  ChatRoomState({
    this.messages = const [],
    this.isLoading = true,
    this.isSending = false,
    this.isZegoReady = false,
    this.zegoStatus = 'Connecting...',
    this.replyingTo,
    this.isRemoteTyping = false,
    this.error,
  });

  ChatRoomState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isSending,
    bool? isZegoReady,
    String? zegoStatus,
    Message? replyingTo,
    bool? isRemoteTyping,
    String? error,
    bool clearReply = false,
    bool clearError = false,
  }) {
    return ChatRoomState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      isZegoReady: isZegoReady ?? this.isZegoReady,
      zegoStatus: zegoStatus ?? this.zegoStatus,
      replyingTo: clearReply ? null : (replyingTo ?? this.replyingTo),
      isRemoteTyping: isRemoteTyping ?? this.isRemoteTyping,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatRoomViewModel extends Notifier<ChatRoomState> {
  ChatRoomViewModel(this._channelId);
  
  final int _channelId;
  StreamSubscription? _zegoSub;
  StreamSubscription? _callLogSub;
  String get _roomID => 'chat_channel_$_channelId';
  String? _targetId;
  String? _targetName;
  
  Timer? _typingTimer;
  bool _isDisposed = false;
  bool _lastSentTypingState = false;

  @override
  ChatRoomState build() {
    _isDisposed = false;
    Future.microtask(() => _init());

    ZegoCallManager.isRoomLogged.addListener(_onZegoStateChanged);
    ZegoCallManager.serviceStatus.addListener(_onZegoStateChanged);
    ZegoCallManager.accountHealth.addListener(_onZegoStateChanged);
    
    _callLogSub = ZegoCallManager.onCallLogReceived.listen(_onCallLogReceived);
    
    ref.onDispose(() {
      _isDisposed = true;
      ZegoCallManager.isRoomLogged.removeListener(_onZegoStateChanged);
      ZegoCallManager.serviceStatus.removeListener(_onZegoStateChanged);
      ZegoCallManager.accountHealth.removeListener(_onZegoStateChanged);
      ZegoCallManager.logoutRoom(_roomID).catchError((_) {});
      _zegoSub?.cancel();
      _callLogSub?.cancel();
      _typingTimer?.cancel();
    });

    // Initialize state with current Zego login status
    return ChatRoomState(
      isZegoReady: ZegoCallManager.isRoomLogged.value,
      zegoStatus: ZegoCallManager.serviceStatus.value,
    );
  }

  void _onCallLogReceived(CallLogData log) {
    if (_isDisposed) return;
    
    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch,
      createdAt: log.timestamp,
      isMine: false, // Call logs are system messages
      kind: MessageKind.callLog,
      callLog: log,
    );

    state = state.copyWith(messages: [...state.messages, newMessage]);
    
    // PERSIST: Post the call log to the backend
    final durationStr = log.durationSeconds > 0 ? ' (${log.durationSeconds}s)' : '';
    final typeStr = log.isVideo ? 'Video' : 'Voice';
    final statusStr = log.isMissed ? 'Missed' : 'Completed';
    final body = '$statusStr $typeStr Call$durationStr';
    
    ref.read(chatServiceProvider).send(_channelId, body);
  }

  void setTargetInfo(String? id, String? name) {
    _targetId = id;
    _targetName = name;
  }

  void _onZegoStateChanged() {
    if (!_isDisposed) {
      String currentHealth = ZegoCallManager.accountHealth.value;
      String currentStatus = ZegoCallManager.serviceStatus.value;
      
      state = state.copyWith(
        isZegoReady: ZegoCallManager.isRoomLogged.value,
        zegoStatus: (currentHealth != 'Healthy (Active)' && currentHealth != 'Unknown') 
            ? currentHealth 
            : currentStatus,
      );
    }
  }

  Future<void> _init() async {
    try {
      debugPrint('ZEGO: Initializing chat for channel: $_channelId. RoomID: $_roomID');
      
      // Note: OpenChannel might still need the actual database channel ID if we want persistence.
      // But for now, we prioritize Zego room synchronization.
      final msgs = await ref.read(chatServiceProvider).openChannel(_channelId);
      if (_isDisposed) return;
      state = state.copyWith(messages: msgs, isLoading: false);

      final user = ref.read(authProvider).user;
      if (user == null) {
        debugPrint('ZEGO: Auth user is null, cannot login to Zego room.');
        return;
      }

      // Ensure user ID and Name are valid strings for Zego
      final zegoUserId = user.id.toString();
      final zegoUserName = (user.name == 'Guest' || user.name.isEmpty) ? user.phone : user.name;

      await ZegoCallManager.loginRoom(_roomID, zegoUserId, zegoUserName);

      _zegoSub?.cancel();
      _zegoSub = ZegoCallManager.onMessageReceived.listen((zegoMsg) {
        if (_isDisposed) return;
        
        debugPrint('📥 LIVE_MESSAGE_RECEIVED from ${zegoMsg.user.id}: ${zegoMsg.message}');
        
        if (zegoMsg.user.id == zegoUserId) {
          debugPrint('📥 Ignoring self-message');
          return; 
        }

        try {
          final data = jsonDecode(zegoMsg.message);
          debugPrint('📥 LIVE_MESSAGE_DECODED: $data');

          if (data['kind'] == 'TYPING') {
            state = state.copyWith(isRemoteTyping: data['isTyping'] ?? false);
            return;
          }

          // DEDUPLICATION: Check if message ID already exists
          final int msgId = zegoMsg.messageID.hashCode;
          if (state.messages.any((m) => m.id == msgId)) {
            debugPrint('📥 DUPLICATE_MESSAGE_IGNORED ($msgId)');
            return;
          }

          Message? newMessage;

          if (data['kind'] == 'CALL_LOG') {
            debugPrint('📥 PROCESSING_CALL_LOG');
            newMessage = Message(
              id: msgId,
              createdAt: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
              isMine: false,
              kind: MessageKind.callLog,
              callLog: CallLogData(
                isVideo: data['isVideo'] ?? false,
                isMissed: data['isMissed'] ?? false,
                durationSeconds: data['duration'] ?? 0,
                timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
              ),
            );
          } else if (data['kind'] == 'IMAGE') {
            debugPrint('📥 IMAGE_DATA_PARSED: ${data['url']}');
            newMessage = Message(
              id: msgId,
              createdAt: DateTime.fromMillisecondsSinceEpoch(zegoMsg.timestamp),
              isMine: false,
              kind: MessageKind.image,
              text: data['url'], // Image URL
              caption: data['caption'],
            );
          } else if (data['kind'] == 'FILE') {
            debugPrint('📥 FILE_DATA_PARSED: ${data['fileName']}');
            newMessage = Message(
              id: msgId,
              createdAt: DateTime.fromMillisecondsSinceEpoch(zegoMsg.timestamp),
              isMine: false,
              kind: MessageKind.file,
              text: data['url'], // File URL
              fileName: data['fileName'],
            );
          } else {
            // TEXT
            debugPrint('📥 TEXT_DATA_PARSED');
            newMessage = Message(
              id: msgId,
              text: data['text'] ?? zegoMsg.message,
              createdAt: DateTime.fromMillisecondsSinceEpoch(zegoMsg.timestamp),
              isMine: false,
              replyTo: data['replyTo'] != null ? Message(id: 0, text: data['replyTo'], createdAt: DateTime.now(), isMine: true) : null,
            );
          }

          debugPrint('📥 UI_UPDATE_TRIGGERED. Messages count: ${state.messages.length + 1}');
          state = state.copyWith(
            messages: [...state.messages, newMessage],
            isRemoteTyping: false,
          );
        } catch (e) {
          debugPrint('📥 PARSE_ERROR: $e');
          final newMessage = Message(
            id: zegoMsg.messageID.hashCode,
            text: zegoMsg.message,
            createdAt: DateTime.fromMillisecondsSinceEpoch(zegoMsg.timestamp),
            isMine: false,
          );
          state = state.copyWith(
            messages: [...state.messages, newMessage],
            isRemoteTyping: false,
          );
        }
      });
    } catch (e) {
      debugPrint('ZEGO: Init error: $e');
      if (!_isDisposed) state = state.copyWith(isLoading: false);
    }
  }

  void onTyping(String text) {
    if (!state.isZegoReady) return;
    bool isCurrentlyTyping = text.isNotEmpty;
    if (isCurrentlyTyping != _lastSentTypingState) {
      _lastSentTypingState = isCurrentlyTyping;
      ZegoCallManager.sendTyping(_roomID, isCurrentlyTyping);
    }
    _typingTimer?.cancel();
    if (isCurrentlyTyping) {
      _typingTimer = Timer(const Duration(seconds: 4), () {
        if (!_isDisposed && _lastSentTypingState) {
          _lastSentTypingState = false;
          ZegoCallManager.sendTyping(_roomID, false);
        }
      });
    }
  }

  Future<void> sendText(String text) async {
    if (text.trim().isEmpty || state.isSending) return;
    
    // Stop typing indicator logic
    _typingTimer?.cancel();
    _lastSentTypingState = false;

    final localMsg = Message(
      id: DateTime.now().millisecondsSinceEpoch,
      text: text,
      createdAt: DateTime.now(),
      isMine: true,
      replyTo: state.replyingTo,
    );

    final replySnippet = state.replyingTo?.snippet;
    state = state.copyWith(
      messages: [...state.messages, localMsg],
      isSending: true,
      clearReply: true,
    );

    try {
      bool isLogged = ZegoCallManager.isRoomLogged.value;
      debugPrint('ZEGO: isRoomLogged check (text): $isLogged');

      if (!isLogged) {
        debugPrint('ZEGO: Room not logged in for text broadcast. Attempting re-login...');
        final user = ref.read(authProvider).user;
        if (user != null) {
          await ZegoCallManager.loginRoom(_roomID, user.id, user.name);
          isLogged = ZegoCallManager.isRoomLogged.value;
        }
      }

      if (isLogged) {
        // Send to backend for persistence
        debugPrint('ZEGO: Posting text to backend...');
        await ref.read(chatServiceProvider).send(_channelId, text);

        // Send actual message via Zego
        debugPrint('ZEGO: Sending text via Zego...');
        final sent = await ZegoCallManager.sendChatMessage(_roomID, text, replyTo: replySnippet);
        
        if (sent) {
          debugPrint('ZEGO: Text dispatched successfully');
        } else {
          debugPrint('ZEGO: Text dispatch failed (returned false)');
        }
        
        // Wait a bit before turning off typing to prevent message collision
        await Future.delayed(const Duration(milliseconds: 300));
        await ZegoCallManager.sendTyping(_roomID, false);
      } else {
        debugPrint('ZEGO: Cannot send text, room still not logged in.');
      }
    } catch (e) {
      debugPrint('ZEGO: Send text error: $e');
    } finally {
      if (!_isDisposed) state = state.copyWith(isSending: false);
    }
  }

  Future<void> sendFile(File file, String type, {String? caption}) async {
    if (state.isSending) return;
    state = state.copyWith(isSending: true);

    try {
      final String fileName = file.path.split('/').last;
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      debugPrint('📤 IMAGE_SEND_START: ${file.path}');

      // Show local version immediately for the sender
      final localMsg = Message(
        id: int.parse(timestamp.hashCode.toString()),
        text: file.path, 
        kind: type == 'image' ? MessageKind.image : MessageKind.file,
        fileName: fileName,
        caption: caption,
        createdAt: DateTime.now(),
        isMine: true,
      );

      state = state.copyWith(messages: [...state.messages, localMsg]);

      // Upload to server
      debugPrint('📤 UPLOADING_IMAGE_TO_SERVER...');
      final serverUrl = await ref.read(chatServiceProvider).upload(file);
      
      if (serverUrl == null) {
        debugPrint('❌ UPLOAD_FAILED_404: Endpoint not found on server or internal error');
        if (!_isDisposed) {
          state = state.copyWith(
            isSending: false,
            error: 'Server Error: Image upload failed (404).',
          );
        }
        return;
      }

      debugPrint('📤 IMAGE_UPLOAD_SUCCESS. URL: $serverUrl');

      // PERSIST: Save the image URL to the backend database
      debugPrint('📤 POSTING_IMAGE_TO_BACKEND...');
      await ref.read(chatServiceProvider).send(_channelId, serverUrl);

      // Room login check
      bool isLogged = ZegoCallManager.isRoomLogged.value;
      if (!isLogged) {
        debugPrint('📤 ROOM_NOT_LOGGED_IN. Attempting re-login...');
        final user = ref.read(authProvider).user;
        if (user != null) {
          await ZegoCallManager.loginRoom(_roomID, user.id, user.name);
          isLogged = ZegoCallManager.isRoomLogged.value;
        }
      }

      if (isLogged) {
        final data = {
          'kind': type == 'image' ? 'IMAGE' : 'FILE',
          'url': serverUrl,
          'fileName': fileName,
          'caption': caption,
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        final jsonStr = jsonEncode(data);
        debugPrint('📤 IMAGE_BROADCAST_SENT: $jsonStr');

        ZegoCallManager.sendTyping(_roomID, false);
        await Future.delayed(const Duration(milliseconds: 300));
        
        final success = await ZegoUIKit().sendInRoomMessage(jsonStr);
        if (success) {
          debugPrint('📤 BROADCAST_SUCCESS');
        } else {
          debugPrint('📤 BROADCAST_FAILED (Zego error)');
        }
      } else {
        debugPrint('📤 CANNOT_BROADCAST: Room still not logged in.');
      }
    } catch (e) {
      debugPrint('📤 SEND_FILE_EXCEPTION: $e');
    } finally {
      if (!_isDisposed) state = state.copyWith(isSending: false);
    }
  }

  void setReplyingTo(Message? msg) {
    if (!_isDisposed) state = state.copyWith(replyingTo: msg);
  }

  void clearError() {
    if (!_isDisposed) state = state.copyWith(clearError: true);
  }

  Future<void> startCall(bool isVideo) async {
    if (_targetId == null) return;
    ZegoCallManager.startCall(isVideo: isVideo, targetUserID: _targetId!, targetUserName: _targetName ?? 'User');
  }
}

final chatRoomViewModelProvider = NotifierProvider.family<ChatRoomViewModel, ChatRoomState, int>((arg) {
  return ChatRoomViewModel(arg);
});
