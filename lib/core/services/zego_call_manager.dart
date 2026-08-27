import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import '../chat/chat_models.dart';

class ZegoCallManager {
  static const int appID = 638927771;
  static const String appSign = 'ef60891e8eb54cdf431f1c05e03c76aca7907e006e8f524990013122facd8872';

  static final ValueNotifier<bool> isRoomLogged = ValueNotifier(false);
  static final ValueNotifier<String> serviceStatus = ValueNotifier('Initializing...');
  static final ValueNotifier<String> accountHealth = ValueNotifier('Unknown');
  static final StreamController<ZegoInRoomMessage> _messageController = StreamController.broadcast();
  static Stream<ZegoInRoomMessage> get onMessageReceived => _messageController.stream;
  
  static final StreamController<CallLogData> _callLogController = StreamController.broadcast();
  static Stream<CallLogData> get onCallLogReceived => _callLogController.stream;

  static bool _isListeningMessages = false;
  static bool _isServiceInitialized = false;

  static String? _currentRoomID;
  static DateTime? _callStartTime;
  static bool _isCurrentCallVideo = false;

  static Future<void> initService(String userID, String userName) async {
    if (_isServiceInitialized) return;

    await ZegoUIKitPrebuiltCallInvitationService().init(
      appID: appID,
      appSign: appSign,
      userID: userID,
      userName: userName,
      plugins: [ZegoUIKitSignalingPlugin()],
      requireConfig: (ZegoCallInvitationData invitation) {
        final config = invitation.invitees.length > 1
            ? ZegoCallInvitationType.videoCall == invitation.type
                ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
                : ZegoUIKitPrebuiltCallConfig.groupVoiceCall()
            : ZegoCallInvitationType.videoCall == invitation.type
                ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

        config.video = ZegoUIKitVideoConfig.preset1080P();
        config.audioVideoView.isVideoMirror = true;
        config.enableAccidentalTouchPrevention = false;
        config.useSpeakerWhenJoining = true; 

        return config;
      },
      events: ZegoUIKitPrebuiltCallEvents(
        onCallEnd: (ZegoCallEndEvent event, VoidCallback defaultAction) {
          final duration = _callStartTime != null 
              ? DateTime.now().difference(_callStartTime!).inSeconds 
              : 0;
          
           debugPrint('ZEGO: Call ended. Duration: $duration seconds. Cleaning up audio...');
          
          _callLogController.add(CallLogData(
            isVideo: _isCurrentCallVideo,
            durationSeconds: duration,
            timestamp: DateTime.now(),
          ));
          
          _callStartTime = null;
          _isCurrentCallVideo = false; // RESET after end
          
          // Force stop all local audio/video and leave to ensure silence
          final lastRoom = _currentRoomID;
          isRoomLogged.value = false;
          
          ZegoUIKit().leaveRoom().then((_) {
            if (lastRoom != null) {
              debugPrint('ZEGO: Re-joining chat room after call: $lastRoom');
              ZegoUIKit().joinRoom(lastRoom).then((result) {
                if (result.errorCode == 0) {
                  isRoomLogged.value = true;
                }
              });
            }
          });

          defaultAction.call();
        },
      ),
      invitationEvents: ZegoUIKitPrebuiltCallInvitationEvents(
        onIncomingCallReceived: (String callID, ZegoCallUser caller, ZegoCallInvitationType callType, List<ZegoCallUser> callees, String customData) {
          debugPrint('ZEGO: Incoming call received. Type: $callType');
          _isCurrentCallVideo = callType == ZegoCallInvitationType.videoCall;
        },
        onOutgoingCallAccepted: (String callID, ZegoCallUser callee) {
          debugPrint('ZEGO: Outgoing call accepted');
          _callStartTime = DateTime.now();
        },
        onOutgoingCallDeclined: (String callID, ZegoCallUser callee, String data) {
          debugPrint('ZEGO: Outgoing call rejected');
          _callLogController.add(CallLogData(
            isVideo: _isCurrentCallVideo,
            isMissed: true,
            timestamp: DateTime.now(),
          ));
        },
        onOutgoingCallTimeout: (String callID, List<ZegoCallUser> callees, bool isVideoCall) {
          debugPrint('ZEGO: Outgoing call timeout');
          _callLogController.add(CallLogData(
            isVideo: _isCurrentCallVideo,
            isMissed: true,
            timestamp: DateTime.now(),
          ));
        },
        onIncomingCallAcceptButtonPressed: () {
          debugPrint('ZEGO: Incoming call accepted (button pressed)');
          _callStartTime = DateTime.now();
        },
        onIncomingCallTimeout: (String callID, ZegoCallUser inviter) {
          debugPrint('ZEGO: Incoming call timeout');
          _callLogController.add(CallLogData(
            isVideo: _isCurrentCallVideo, 
            isMissed: true,
            timestamp: DateTime.now(),
          ));
        },
        onIncomingCallCanceled: (String callID, ZegoCallUser caller, String customData) {
          debugPrint('ZEGO: Incoming call canceled');
          _callLogController.add(CallLogData(
            isVideo: _isCurrentCallVideo,
            isMissed: true,
            timestamp: DateTime.now(),
          ));
        },
      ),
    );
    _isServiceInitialized = true;
    _startListeningMessages();
    _startRoomStateWatchdog();
  }

  static void _startRoomStateWatchdog() {
    ZegoUIKit().getRoomStateStream().addListener(() {
      final state = ZegoUIKit().getRoomStateStream().value;
      debugPrint('ZEGO: HEALTH_CHECK -> Room State: ${state.reason}, Error: ${state.errorCode}');
      
      if (state.errorCode != 0) {
        String healthMsg = 'Error ${state.errorCode}';
        if (state.errorCode == 1002001 || state.errorCode == 1001005) {
          healthMsg = 'ZEGO PLAN LIMIT REACHED';
        } else if (state.errorCode == 1002011) {
          healthMsg = 'ZEGO ACCOUNT EXPIRED/FROZEN';
        } else if (state.errorCode == 1002002) {
          healthMsg = 'INVALID APP ID/SIGN';
        }
        accountHealth.value = healthMsg;
        serviceStatus.value = healthMsg;
      } else if (state.reason == ZegoRoomStateChangedReason.Logined) {
        accountHealth.value = 'Healthy (Active)';
        serviceStatus.value = 'Online';
        isRoomLogged.value = true;
      } else if (state.reason == ZegoRoomStateChangedReason.Logout) {
        isRoomLogged.value = false;
        serviceStatus.value = 'Offline';
      }
    });
  }

  static void _startListeningMessages() {
    if (_isListeningMessages) return;
    _isListeningMessages = true;
    
    ZegoUIKit().getInRoomMessageStream().listen((dynamic event) {
      if (event is List) {
        for (var m in event) {
           if (m is ZegoInRoomMessage) {
             debugPrint('ZEGO: InRoomMessage received from ${m.user.id}: ${m.message}');
             _messageController.add(m);
           }
        }
      } else if (event is ZegoInRoomMessage) {
         debugPrint('ZEGO: InRoomMessage received from ${event.user.id}: ${event.message}');
         _messageController.add(event);
      }
    });
  }

  static void uninitService() {
    ZegoUIKitPrebuiltCallInvitationService().uninit();
    _isServiceInitialized = false;
  }

  static Future<void> loginRoom(String roomID, String userID, String userName) async {
    try {
      debugPrint('ZEGO: Attempting login and join room: $roomID for user: $userID ($userName)');
      
      // Clear previous state
      isRoomLogged.value = false;
      serviceStatus.value = 'Connecting...';
      
      debugPrint('ZEGO: Logging in user...');
      ZegoUIKit().login(userID, userName);
      
      // Small delay before joining to ensure login triggers
      await Future.delayed(const Duration(milliseconds: 500));
      
      debugPrint('ZEGO: Joining room...');
      final result = await ZegoUIKit().joinRoom(roomID);
      
      if (result.errorCode == 0) {
        await Future.delayed(const Duration(milliseconds: 500)); // Stabilization
        isRoomLogged.value = true;
        serviceStatus.value = 'Online';
        debugPrint('ZEGO: Room Join Success: $roomID');
      } else {
        String errorMsg = 'Connection Failed (${result.errorCode})';
        if (result.errorCode == 1002001 || result.errorCode == 1002011) {
          errorMsg = 'Zego Plan Limit Reached';
        } else if (result.errorCode == 1001001) {
          errorMsg = 'Network Error';
        }
        serviceStatus.value = errorMsg;
        debugPrint('ZEGO: Room Join Failed: ${result.errorCode}');
        isRoomLogged.value = false;
      }
      _startListeningMessages();
    } catch (e) {
      String errorStr = e.toString();
      if (errorStr.contains('SocketException')) {
        serviceStatus.value = 'No Internet';
      } else {
        serviceStatus.value = 'Error: $e';
      }
      debugPrint('ZEGO: Login room error: $e');
      isRoomLogged.value = false;
    }
  }

  static Future<void> logoutRoom(String roomID) async {
    try {
      debugPrint('ZEGO: Leaving room: $roomID');
      await ZegoUIKit().leaveRoom();
    } catch (e) {
      debugPrint('ZEGO: Error leaving room: $e');
    } finally {
      isRoomLogged.value = false;
    }
  }

  static Future<bool> sendChatMessage(String roomID, String text, {String? replyTo}) async {
    final data = {
      'kind': 'TEXT',
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    };
    if (replyTo != null) data['replyTo'] = replyTo;
    
    final jsonStr = jsonEncode(data);
    debugPrint('ZEGO: Sending in-room message: $jsonStr to room: $roomID');

    try {
      final success = await ZegoUIKit().sendInRoomMessage(jsonStr);
      if (success) {
        debugPrint('ZEGO: Message sent successfully');
        return true;
      } else {
        debugPrint('ZEGO: Send message failed');
        return false;
      }
    } catch (e) {
      debugPrint('ZEGO: Send exception: $e');
      return false;
    }
  }

  static Future<void> sendTyping(String roomID, bool isTyping) async {
    try {
      await ZegoUIKit().sendInRoomMessage(jsonEncode({'kind': 'TYPING', 'isTyping': isTyping}));
    } catch (_) {}
  }

  static Future<void> startCall({required bool isVideo, required String targetUserID, required String targetUserName}) async {
    _isCurrentCallVideo = isVideo;
    ZegoUIKitPrebuiltCallInvitationService().send(
      invitees: [ZegoCallUser(targetUserID, targetUserName)],
      isVideoCall: isVideo,
    );
  }
}
