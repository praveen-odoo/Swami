/// Plain data models. `titleHi` / `titleEn` pairs let every screen
/// switch language instantly without re-fetching anything.
class Quote {
  const Quote({required this.textHi, required this.textEn, required this.source});
  final String textHi;
  final String textEn;
  final String source;
}

class Pravachan {
  const Pravachan({
    required this.id,
    required this.titleHi,
    required this.titleEn,
    required this.descriptionHi,
    required this.descriptionEn,
    required this.imageUrl,
    this.videoUrl = '',
    this.youtubeId = '',
    required this.durationMin,
    required this.date,
  });

  final String id;
  final String titleHi;
  final String titleEn;
  final String descriptionHi;
  final String descriptionEn;
  final String imageUrl;

  /// Direct .mp4 stream URL (used only if [youtubeId] is empty).
  final String videoUrl;

  /// YouTube video ID, e.g. for https://youtu.be/ABC123xyz it is 'ABC123xyz'.
  /// When set, the app plays this YouTube video instead of [videoUrl].
  final String youtubeId;

  final int durationMin;
  final DateTime date;

  bool get isYouTube => youtubeId.isNotEmpty;
}

class Bhajan {
  const Bhajan({
    required this.id,
    required this.titleHi,
    required this.titleEn,
    required this.singerHi,
    required this.singerEn,
    required this.imageUrl,
    required this.audioUrl,
    required this.durationSec,
  });

  final String id;
  final String titleHi;
  final String titleEn;
  final String singerHi;
  final String singerEn;
  final String imageUrl;

  /// Direct .mp3 stream URL (sample test audio — replace with your media).
  final String audioUrl;
  final int durationSec;
}

class EventItem {
  const EventItem({
    required this.id,
    required this.titleHi,
    required this.titleEn,
    required this.venueHi,
    required this.venueEn,
    required this.imageUrl,
    required this.date,
  });

  final String id;
  final String titleHi;
  final String titleEn;
  final String venueHi;
  final String venueEn;
  final String imageUrl;
  final DateTime date;
}

class Book {
  const Book({
    required this.id,
    required this.titleHi,
    required this.titleEn,
    required this.summaryHi,
    required this.summaryEn,
    required this.imageUrl,
    required this.pages,
  });

  final String id;
  final String titleHi;
  final String titleEn;
  final String summaryHi;
  final String summaryEn;
  final String imageUrl;
  final int pages;
}

class GalleryImage {
  const GalleryImage({required this.url, required this.captionHi, required this.captionEn});
  final String url;
  final String captionHi;
  final String captionEn;
}

/// A seva / mission area of Shambhavi Peeth (gau seva, education, etc.)
/// shown on the Home screen as "Our Seva Work".
class SevaKarya {
  const SevaKarya({
    required this.titleHi,
    required this.titleEn,
    required this.descHi,
    required this.descEn,
    required this.imageUrl,
  });

  final String titleHi;
  final String titleEn;
  final String descHi;
  final String descEn;
  final String imageUrl;
}