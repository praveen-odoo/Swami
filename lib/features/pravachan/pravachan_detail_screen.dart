import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';

/// Discourse detail screen.
///
/// Plays EITHER:
///  - a YouTube video (when pravachan.youtubeId is set) via
///    youtube_player_flutter — full YouTube controls, fullscreen, quality; or
///  - a direct .mp4 stream via Chewie (seek, skip, volume, fullscreen).
class PravachanDetailScreen extends StatefulWidget {
  const PravachanDetailScreen({super.key, required this.pravachan});

  final Pravachan pravachan;

  @override
  State<PravachanDetailScreen> createState() => _PravachanDetailScreenState();
}

class _PravachanDetailScreenState extends State<PravachanDetailScreen> {
  // --- YouTube ---
  YoutubePlayerController? _yt;

  // --- mp4 (Chewie) ---
  VideoPlayerController? _video;
  ChewieController? _chewie;

  bool _loading = false;
  bool _started = false;
  String? _errorText;

  static const String _backupUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

  @override
  void dispose() {
    // Note: youtube_player_flutter 10.x controller doesn't have a manual dispose() 
    // that needs to be called here for basic usage, but we'll follow standard practices.
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------- mp4 helpers
  Future<VideoPlayerController?> _tryInit(String url) async {
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await c.initialize().timeout(const Duration(seconds: 30));
      return c;
    } catch (e) {
      debugPrint('Video init failed for $url -> $e');
      await c.dispose();
      return null;
    }
  }

  // --------------------------------------------------------------- start
  Future<void> _startVideo() async {
    if (_loading || _started) return;
    setState(() {
      _loading = true;
      _errorText = null;
    });

    // -------- YouTube path --------
    if (widget.pravachan.isYouTube) {
      // In 10.x, initialVideoId is gone, use the factory or load() later.
      // But standard way is passing it to the controller.
      _yt = YoutubePlayerController.fromVideoId(
        videoId: widget.pravachan.youtubeId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          mute: false,
        ),
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _started = true;
      });
      return;
    }

    // -------- mp4 path (with fallback) --------
    var controller = await _tryInit(widget.pravachan.videoUrl);
    controller ??= await _tryInit(_backupUrl);

    if (!mounted) {
      controller?.dispose();
      return;
    }
    if (controller == null) {
      setState(() {
        _loading = false;
        _errorText = context.tr('videoError');
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('videoError'))));
      return;
    }

    final chewie = ChewieController(
      videoPlayerController: controller,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      allowPlaybackSpeedChanging: true,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.gold,
        handleColor: AppColors.goldLight,
        bufferedColor: Colors.white38,
        backgroundColor: Colors.white24,
      ),
      placeholder: Container(color: Colors.black),
      aspectRatio: controller.value.aspectRatio == 0
          ? 16 / 9
          : controller.value.aspectRatio,
      errorBuilder: (context, errorMessage) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(context.tr('videoError'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white)),
        ),
      ),
    );

    setState(() {
      _video = controller;
      _chewie = chewie;
      _loading = false;
      _started = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // In 10.x, YoutubePlayerBuilder is no longer needed.
    // Fullscreen and rotation are handled internally.
    return _scaffold(context);
  }

  Widget _scaffold(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isHindi = locale.languageCode == 'hi';
    final p = widget.pravachan;

    final ytPlayer = (_started && p.isYouTube && _yt != null)
        ? YoutubePlayer(controller: _yt!)
        : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: ytPlayer != null ? 0 : 260,
            pinned: true,
            flexibleSpace: ytPlayer == null
                ? FlexibleSpaceBar(background: _buildHeader(p))
                : null,
            title: ytPlayer != null
                ? Text(isHindi ? p.titleHi : p.titleEn,
                style: const TextStyle(fontSize: 16))
                : null,
          ),
          if (ytPlayer != null)
            SliverToBoxAdapter(child: ytPlayer),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isHindi ? p.titleHi : p.titleEn,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _Meta(
                        icon: Icons.schedule,
                        text: '${p.durationMin} ${context.tr('minutes')}',
                      ),
                      _Meta(
                        icon: Icons.calendar_today_outlined,
                        text: DateFormat.yMMMd(isHindi ? 'hi' : 'en')
                            .format(p.date),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(context.tr('aboutPravachan'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    isHindi ? p.descriptionHi : p.descriptionEn,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.7),
                  ),
                  const SizedBox(height: 16),
                  if (_errorText != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.wifi_off,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorText!,
                              style:
                              const TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Show "Watch now" only for mp4 (YouTube autoplays in header).
                  if (!_started && !p.isYouTube)
                    GoldButton(
                      label: _errorText == null
                          ? context.tr('watchNow')
                          : context.tr('retry'),
                      icon: Icons.play_circle_outline,
                      busy: _loading,
                      onPressed: _startVideo,
                    ),
                  // For YouTube, before start show a play button too.
                  if (!_started && p.isYouTube)
                    GoldButton(
                      label: context.tr('watchNow'),
                      icon: Icons.play_circle_outline,
                      busy: _loading,
                      onPressed: _startVideo,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Pravachan p) {
    final chewie = _chewie;
    final video = _video;
    if (_started &&
        chewie != null &&
        video != null &&
        video.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: Chewie(controller: chewie),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        AppNetworkImage(url: p.imageUrl),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, AppColors.maroonDark],
            ),
          ),
        ),
        Center(
          child: GestureDetector(
            onTap: _startVideo,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.goldGradient,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.gold.withOpacity(0.6), blurRadius: 24),
                ],
              ),
              child: _loading
                  ? const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: AppColors.maroonDark),
              )
                  : const Icon(Icons.play_arrow,
                  size: 40, color: AppColors.maroonDark),
            ),
          ),
        ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.gold),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
