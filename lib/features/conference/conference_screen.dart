import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zego_uikit_prebuilt_video_conference/zego_uikit_prebuilt_video_conference.dart';
import '../../core/providers/providers.dart';
import '../../core/services/zego_call_manager.dart';
import '../../core/theme/app_colors.dart';

class ConferenceScreen extends ConsumerWidget {
  const ConferenceScreen({
    super.key,
    required this.conferenceID,
    this.title = 'Satsang',
  });

  final String conferenceID;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to join the Satsang')),
      );
    }

    // Force a clean Dark Theme to use Zego's default professional styles
    // This prevents the app's global light theme from breaking the chat input
    return Theme(
      data: ThemeData.dark().copyWith(
        inputDecorationTheme: const InputDecorationTheme(), // Resets to Material/Zego defaults
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: ZegoUIKitPrebuiltVideoConference(
            appID: ZegoCallManager.appID,
            appSign: ZegoCallManager.appSign,
            conferenceID: conferenceID,
            userID: user.id,
            userName: user.name,
            config: ZegoUIKitPrebuiltVideoConferenceConfig()
              ..turnOnCameraWhenJoining = true
              ..turnOnMicrophoneWhenJoining = true
              ..useSpeakerWhenJoining = true
              ..audioVideoViewConfig.isVideoMirror = true
              ..layout = ZegoLayout.gallery(
                addBorderRadiusAndSpacingBetweenView: true,
              )
              ..topMenuBarConfig.title = title
              ..topMenuBarConfig.isVisible = true
              ..topMenuBarConfig.extendButtons = [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white, size: 20),
                  onPressed: () => _shareMeetingLink(conferenceID),
                ),
              ]
              ..bottomMenuBarConfig.buttons = [
                ZegoMenuBarButtonName.toggleMicrophoneButton,
                ZegoMenuBarButtonName.toggleCameraButton,
                ZegoMenuBarButtonName.switchCameraButton,
                ZegoMenuBarButtonName.chatButton,
                ZegoMenuBarButtonName.leaveButton,
              ],
          ),
        ),
      ),
    );
  }

  static void _shareMeetingLink(String id) {
    final appUrl = 'satsang://join?id=$id';
    Share.share(
      '🙏 Jai Shri Ram! Join our Spiritual Satsang with Swami Ji.\n\n'
      '📱 Join via App Link: $appUrl\n\n'
      '🔢 Or enter manually in App:\nGo to "Live Satsang" > Enter Code: $id\n\n'
      'Join us for a divine experience.',
      subject: 'Satsang Invitation',
    );
  }
}

class JoinConferenceScreen extends StatefulWidget {
  const JoinConferenceScreen({super.key});

  @override
  State<JoinConferenceScreen> createState() => _JoinConferenceScreenState();
}

class _JoinConferenceScreenState extends State<JoinConferenceScreen> {
  final _idController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _idController.text = '108-1008';
  }

  void _generateNewNumericCode() {
    final rand = Random();
    String part() => (rand.nextInt(900) + 100).toString();
    setState(() {
      _idController.text = '${part()}-${part()}-${part()}';
    });
  }

  void _shareLink() {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please generate or enter a code first')));
      return;
    }
    ConferenceScreen._shareMeetingLink(id);
  }

  void _copyToClipboard() {
    if (_idController.text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _idController.text.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code Copied to Clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Satsang'),
        backgroundColor: AppColors.maroon,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.maroon.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.video_camera_front_rounded, size: 64, color: AppColors.maroon),
              ),
              const SizedBox(height: 32),
              const Text(
                'Satsang Video Conference',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.maroonDark),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter the Satsang ID below to join',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 40),
              
              TextField(
                controller: _idController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2.0, color: AppColors.maroonDark),
                decoration: InputDecoration(
                  hintText: 'e.g. 108-501-1008',
                  filled: true,
                  fillColor: AppColors.ivory, // Matches App Theme background
                  contentPadding: const EdgeInsets.all(20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16), 
                    borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.45)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16), 
                    borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.45)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16), 
                    borderSide: const BorderSide(color: AppColors.maroon, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.copy, color: AppColors.maroon),
                    onPressed: _copyToClipboard,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.maroon,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  onPressed: () {
                    final id = _idController.text.trim();
                    if (id.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ConferenceScreen(conferenceID: id)),
                      );
                    }
                  },
                  child: const Text('Join Satsang Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.maroon,
                    side: const BorderSide(color: AppColors.maroon, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _shareLink,
                  icon: const Icon(Icons.share),
                  label: const Text('Share Satsang Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              
              const SizedBox(height: 32),
              const Divider(thickness: 1),
              const SizedBox(height: 16),
              
              TextButton.icon(
                onPressed: _generateNewNumericCode,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Generate New Number ID'),
                style: TextButton.styleFrom(foregroundColor: AppColors.maroon, textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
