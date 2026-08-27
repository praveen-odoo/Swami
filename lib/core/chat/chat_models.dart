import 'package:intl/intl.dart';

enum MessageKind { text, file, image, callLog }

class Message {
  final int id;
  final String? text;
  final DateTime createdAt;
  final bool isMine;
  final MessageKind kind;
  final String? fileName;
  final String? caption;
  final Message? replyTo;
  final CallLogData? callLog;

  Message({
    required this.id,
    this.text,
    required this.createdAt,
    required this.isMine,
    this.kind = MessageKind.text,
    this.fileName,
    this.caption,
    this.replyTo,
    this.callLog,
  });

  String get time => DateFormat('hh:mm a').format(createdAt);
  
  String get dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (msgDate == today) return 'Today';
    if (msgDate == yesterday) return 'Yesterday';
    return DateFormat('dd MMM yyyy').format(createdAt);
  }

  String get snippet {
    if (kind == MessageKind.image) return "📷 Photo";
    if (kind == MessageKind.file) return "📄 File";
    if (kind == MessageKind.callLog) return "📞 ${callLog?.title ?? 'Call'}";
    return text ?? "";
  }

  String? attachmentUrl(String baseUrl) => null;
}

class CallLogData {
  final bool isVideo;
  final bool isMissed;
  final int durationSeconds;
  final DateTime timestamp;

  CallLogData({
    required this.isVideo,
    this.isMissed = false,
    this.durationSeconds = 0,
    required this.timestamp,
  });

  String get title {
    if (isMissed) return isVideo ? "Missed Video Call" : "Missed Voice Call";
    final durationStr = durationSeconds > 0 ? _formatDuration(durationSeconds) : "";
    return isVideo ? "Video Call ($durationStr)" : "Voice Call ($durationStr)";
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$mins:$secs";
  }
}

class Channel {
  final int id;
  final String name;
  final String initials;
  final String preview;
  final DateTime lastMessageAt;
  final int unread;
  final String? targetId;
  final String? targetName;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isSubscriber;

  Channel({
    required this.id,
    required this.name,
    required this.initials,
    required this.preview,
    required this.lastMessageAt,
    required this.unread,
    this.targetId,
    this.targetName,
    this.isOnline = false,
    this.lastSeen,
    this.isSubscriber = false,
  });

  String get time => DateFormat('hh:mm a').format(lastMessageAt);

  String get lastSeenText {
    if (isOnline) return 'Online';
    if (lastSeen == null) return '';
    return 'Last seen ${DateFormat('hh:mm a').format(lastSeen!)}';
  }
}
