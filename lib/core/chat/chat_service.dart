import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../services/api_service.dart';
import 'chat_models.dart';

class ChatService {
  ChatService(this.ref);
  final Ref ref;

  ApiService get _api => ref.read(apiServiceProvider);

  bool get available => true;

  Future<bool> tryRestoreSession() async {
    return true;
  }

  Future<String?> signIn(String email, String password) async {
    return null;
  }

  Future<List<Channel>> channels() async {
    try {
      // The channels endpoint requires a token, which might be missing in OTP login
      final response = await _api.get('/chat/channels', authenticated: true);
      if (response != null && response['data'] is List && (response['data'] as List).isNotEmpty) {
        return (response['data'] as List).map((e) {
          final j = e as Map<String, dynamic>;
          return Channel(
            id: j['id'] as int,
            name: j['name'] as String? ?? 'Channel',
            initials: (j['name'] as String? ?? 'C').characters.take(2).join().toUpperCase(),
            preview: j['last_message_preview'] as String? ?? 'No messages',
            lastMessageAt: DateTime.tryParse(j['last_message_at'] as String? ?? '') ?? DateTime.now(),
            unread: j['unread_count'] as int? ?? 0,
            targetId: j['target_id']?.toString().trim(),
            targetName: j['name'] as String?,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Fetch Channels Error: $e (This is expected if token is missing)');
    }
    
    // Return empty list instead of crashing/throwing on 401 or network error
    return [];
  }

  Future<List<Message>> openChannel(int channelId) async {
    try {
      final response = await _api.get('/chat/messages?channel_id=$channelId', authenticated: true);
      if (response != null && response['data'] is List) {
        final myId = ref.read(authProvider).user?.id;
        return (response['data'] as List).map((e) {
          final j = e as Map<String, dynamic>;
          final authorId = (j['author_id'] ?? '').toString();
          final text = j['body'] as String?;
          
          // Detect if the message is an image URL
          MessageKind kind = MessageKind.text;
          if (text != null && (text.contains('.jpg') || text.contains('.png') || text.contains('.jpeg') || text.contains('image'))) {
            kind = MessageKind.image;
          }

          return Message(
            id: j['id'] as int,
            text: text,
            createdAt: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
            isMine: authorId == myId,
            kind: kind,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Fetch Messages Error: $e');
    }

    // No fallback messages. If API fails, return empty.
    return [];
  }

  Future<List<Channel>> members({bool isSubscriber = false}) async {
    try {
      debugPrint('🚀 [ChatService] Fetching members for Swami Ji (Dynamic Filter: $isSubscriber)');
      
      // We use POST as requested to show the body in the console. 
      // Using explicit boolean true/false as per user preference.
      // Reverted back to is_subscriber as it is proven to work for filtering.
      dynamic res;
      try {
        res = await _api.post('/home', body: {'is_subscriber': isSubscriber}, authenticated: false);
      } catch (e) {
        debugPrint('⚠️ [ChatService] POST /home failed, trying GET fallback... Error: $e');
        res = await _api.get('/home?is_subscriber=$isSubscriber', authenticated: false);
      }

      debugPrint('📥 [ChatService] Members Response for $isSubscriber: $res');
      
      if (res != null && res['data'] != null && res['data'] is Map) {
        final d = res['data'] as Map<String, dynamic>;
        
        // Extract users from profile.member_records
        final profile = d['profile'] as Map<String, dynamic>?;
        final memberRecords = profile?['member_records'];
        
        List<dynamic> rawData = [];
        if (memberRecords is Map) {
          debugPrint('ZEGO: Found member_records Map with ${memberRecords.length} entries.');
          memberRecords.forEach((id, info) {
            if (info is Map) {
              final item = Map<String, dynamic>.from(info);
              item['id'] = id; // Inject ID from key
              rawData.add(item);
            }
          });
        } else {
          // Fallback to previous logic if structure changes
          rawData = (d['users'] ?? d['members'] ?? d['community'] ?? d['partners'] ?? []) as List;
        }
        
        if (rawData.isEmpty) {
          debugPrint('ZEGO: No users found in /home data (isSubscriber=$isSubscriber).');
          return [];
        }

        final myId = ref.read(authProvider).user?.id;
        final membersList = rawData.map((e) {
          if (e is! Map<String, dynamic>) return null;
          final j = e;
          final idStr = (j['id'] ?? j['uid'] ?? j['user_id'] ?? '').toString().trim();
          if (idStr.isEmpty || idStr == myId) return null; // Don't show empty or myself
          
          String name = (j['name'] ?? j['display_name'] ?? j['full_name'] ?? j['user_name'] ?? '').toString();
          
          // Fallback to mobile if name is empty
          if (name.trim().isEmpty || name == 'Guest') {
            name = j['mobile']?.toString() ?? j['phone']?.toString() ?? 'User';
          }

          final initials = name.isNotEmpty ? name.characters.take(2).join().toUpperCase() : 'U';

          // Simulate online status for some members
          final isOnline = int.tryParse(idStr) != null && (int.parse(idStr) % 3 == 0);

          return Channel(
            id: int.tryParse(idStr) ?? 0,
            name: name,
            initials: initials,
            preview: 'Tap to chat',
            lastMessageAt: DateTime.now(),
            unread: 0,
            targetId: idStr,
            targetName: name,
            isOnline: isOnline,
            lastSeen: isOnline ? null : DateTime.now().subtract(const Duration(minutes: 15)),
            isSubscriber: isSubscriber,
          );
        }).whereType<Channel>().toList();
        
        debugPrint('ZEGO: Successfully processed ${membersList.length} members (isSubscriber=$isSubscriber)');
        return membersList;
      } else {
        debugPrint('ZEGO: /home response is null or missing "data" map (isSubscriber=$isSubscriber).');
      }
    } catch (e) {
      debugPrint('ZEGO: Error in members() while fetching from /home (isSubscriber=$isSubscriber): $e');
    }
    return [];
  }

  Future<Message?> send(int channelId, String body, {int? replyToId}) async {
    try {
      final response = await _api.post('/chat/post', body: {
        'channel_id': channelId,
        'body': body,
      }, authenticated: true);
      
      if (response != null && response['data'] != null) {
        final j = response['data'] as Map<String, dynamic>;
        return Message(
          id: j['id'] as int? ?? DateTime.now().millisecondsSinceEpoch,
          text: body,
          createdAt: DateTime.now(),
          isMine: true,
        );
      }
    } catch (e) {
      debugPrint('Send Message Error: $e');
    }
    return null;
  }

  Future<String?> upload(File file) async {
    try {
      final response = await _api.uploadFile('/chat/upload', file, authenticated: true);
      if (response != null && response['data'] != null) {
        return (response['data'] as Map)['url'] as String?;
      }
    } catch (e) {
      debugPrint('Upload Error: $e');
    }
    return null;
  }

  Future<void> signOut() async {
  }
}

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref);
});
