import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'providers.dart';

class PravachanState {
  final bool isLoading;
  final List<Pravachan> items;
  final String? error;

  PravachanState({this.isLoading = false, this.items = const [], this.error});

  PravachanState copyWith({bool? isLoading, List<Pravachan>? items, String? error}) {
    return PravachanState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      error: error,
    );
  }
}

class PravachanNotifier extends Notifier<PravachanState> {
  @override
  PravachanState build() {
    // Re-fetch when apiServiceProvider changes (e.g. on locale change)
    ref.listen(apiServiceProvider, (prev, next) {
      load();
    });
    return PravachanState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final api = ref.read(apiServiceProvider);
      // Assuming there might be a pravachans or videos endpoint in the future
      // For now, we use a try-catch to fallback to sample data if endpoint doesn't exist
      final response = await api.get('/pravachans', authenticated: false).catchError((_) => null);
      
      if (response != null && response['data'] is List) {
        final List<Pravachan> items = (response['data'] as List).map((e) {
          final j = e as Map<String, dynamic>;
          return Pravachan(
            id: j['id'].toString(),
            titleHi: j['title_hi'] ?? j['title'] ?? '',
            titleEn: j['title_en'] ?? j['title'] ?? '',
            descriptionHi: j['description_hi'] ?? j['description'] ?? '',
            descriptionEn: j['description_en'] ?? j['description'] ?? '',
            imageUrl: j['image_base64'] ?? j['image_url'] ?? '',
            youtubeId: j['youtube_id'] ?? '',
            videoUrl: j['video_url'] ?? '',
            durationMin: j['duration_min'] ?? 0,
            date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
          );
        }).toList();
        state = state.copyWith(isLoading: false, items: items);
      } else {
        // If API fails or returns nothing, we stay empty or use sample data logic elsewhere
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final pravachanProvider = NotifierProvider<PravachanNotifier, PravachanState>(PravachanNotifier.new);
