import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/sample_data.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';

/// Bhajan list with a luxurious mini-player streaming REAL audio over
/// the internet (sample MP3s — swap URLs in sample_data.dart).
class BhajanScreen extends ConsumerStatefulWidget {
  const BhajanScreen({super.key});

  @override
  ConsumerState<BhajanScreen> createState() => _BhajanScreenState();
}

class _BhajanScreenState extends ConsumerState<BhajanScreen> {
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription> _subs = [];

  Bhajan? _current;
  bool _playing = false;
  bool _loading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _subs.add(_player.onPositionChanged.listen((d) {
      if (mounted) setState(() => _position = d);
    }));
    _subs.add(_player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    }));
    _subs.add(_player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playing = s == PlayerState.playing);
    }));
    _subs.add(_player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
      }
    }));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  Future<void> _select(Bhajan b) async {
    if (_current?.id == b.id) {
      _togglePlay();
      return;
    }
    setState(() {
      _current = b;
      _loading = true;
      _position = Duration.zero;
      _duration = Duration(seconds: b.durationSec);
    });
    try {
      await _player.stop();
      await _player.play(UrlSource(b.audioUrl));
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('audioError'))));
    }
  }

  Future<void> _togglePlay() async {
    if (_current == null) return;
    if (_playing) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('bhajanList')),
        leading: Navigator.canPop(context) ? const BackButton() : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: SampleData.bhajans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final b = SampleData.bhajans[i];
                final selected = _current?.id == b.id;
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    leading: AppNetworkImage(
                      url: b.imageUrl,
                      width: 56,
                      height: 56,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      isHindi ? b.titleHi : b.titleEn,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                              color: selected
                                  ? AppColors.saffron
                                  : AppColors.textPrimary),
                    ),
                    subtitle: Text(isHindi ? b.singerHi : b.singerEn),
                    trailing: Icon(
                      selected && _playing
                          ? Icons.graphic_eq
                          : Icons.play_circle_outline,
                      color: AppColors.maroon,
                    ),
                    onTap: () => _select(b),
                  ),
                );
              },
            ),
          ),
          if (_current != null) _buildPlayer(isHindi),
        ],
      ),
    );
  }

  Widget _buildPlayer(bool isHindi) {
    final b = _current!;
    final total = _duration.inSeconds == 0
        ? Duration(seconds: b.durationSec)
        : _duration;
    final progress = total.inSeconds == 0
        ? 0.0
        : _position.inSeconds / total.inSeconds;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: const BoxDecoration(
        gradient: AppColors.maroonGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                AppNetworkImage(
                  url: b.imageUrl,
                  width: 52,
                  height: 52,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('nowPlaying'),
                        style: const TextStyle(
                            color: AppColors.goldLight, fontSize: 11),
                      ),
                      Text(
                        isHindi ? b.titleHi : b.titleEn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.onDark,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.6,
                              color: AppColors.goldLight),
                        ),
                      )
                    : IconButton(
                        iconSize: 44,
                        onPressed: _togglePlay,
                        icon: Icon(
                          _playing
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: AppColors.goldLight,
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(_fmt(_position),
                    style: const TextStyle(
                        color: AppColors.onDark, fontSize: 11)),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7),
                      activeTrackColor: AppColors.goldLight,
                      inactiveTrackColor:
                          Colors.white.withValues(alpha: 0.18),
                      thumbColor: AppColors.goldLight,
                      overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14),
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: (v) async {
                        final target = Duration(
                            seconds: (total.inSeconds * v).round());
                        await _player.seek(target);
                      },
                    ),
                  ),
                ),
                Text(_fmt(total),
                    style: const TextStyle(
                        color: AppColors.onDark, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
