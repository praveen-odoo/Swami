import '../models/models.dart';

/// Demo content for Swami Anand Swaroop ji.
///
/// IMAGES: the previous build used guessed URLs from the official website
/// (e.g. /wp-content/uploads/2021/04/1.jpg) which do NOT exist / are
/// hotlink-blocked, so every screen showed a broken-image icon. They are
/// replaced below with reliable, high-availability image URLs for the demo.
///
/// PRODUCTION: replace each URL with your real, verified media links
/// (or bundle local assets — see assets/ in pubspec.yaml).
class SampleData {
  SampleData._();

  // ---------------------------------------------------------------- Images
  // LOCAL bundled images (assets/images/) — your real photos. These ALWAYS
  // load: no internet, no broken links, never expire.
  static const String _swamiPortrait = 'assets/images/swami.jpg';  // Swami ji
  static const String _swamiBanner   = 'assets/images/banner.jpg'; // welcome art
  static const String _gangaBg       = 'assets/images/ganga.jpg';  // Ganga arch
  static const String _gauSeva       = 'assets/images/temple.jpg'; // Swami + gau
  static const String _annadaan      = 'assets/images/seva.jpg';   // Annapurna rasoi
  static const String _eventBg       = 'assets/images/event.jpg';  // Kanyadan vivah
  static const String _education     = 'assets/images/education.jpg'; // Anath shiksha
  static const String _village       = 'assets/images/village.jpg';   // Gram vikas
  static const String _math          = 'assets/images/math.jpg';      // Shambhavi Math
  // aliases used elsewhere in the app
  static const String _spiritualBg   = _gauSeva;
  static const String _meditationBg  = _eventBg;

  // Public portrait used in headers (splash, home, login).
  static const String portrait = _swamiPortrait;
  // Gau-seva photo (Swami ji with cow) — used in the home "About" card.
  static const String aboutImage = _gauSeva;

  // Helpers (kept for backward compatibility).
  static String getPortrait() => _swamiPortrait;
  static String getBanner() => _swamiBanner;

  // ---------------------------------------------------------------- Quotes
  static final quotes = <Quote>[
    const Quote(
      textHi:
      'राष्ट्र रक्षा ही सबसे बड़ा धर्म है। जब तक हमारा राष्ट्र सुरक्षित नहीं होगा, तब तक हमारी संस्कृति और धर्म भी सुरक्षित नहीं रह सकते।',
      textEn:
      'Protection of the nation is the greatest dharma. Until our nation is secure, our culture and religion cannot remain safe.',
      source: 'स्वामी आनंद स्वरूप जी',
    ),
    const Quote(
      textHi:
      'गंगा केवल एक नदी नहीं, वह हमारी संस्कृति की जीवनधारा है। गंगा की रक्षा करना हम सबका सामूहिक कर्तव्य है।',
      textEn:
      'Ganga is not just a river; she is the lifeline of our culture. Protecting Ganga is our collective duty.',
      source: 'स्वामी आनंद स्वरूप जी',
    ),
    const Quote(
      textHi:
      'मानव सेवा ही माधव सेवा है। गरीबों और अनाथों की सहायता करना ही ईश्वर की सच्ची पूजा है।',
      textEn:
      'Service to humanity is service to God. Helping the poor and orphans is the true worship of the Divine.',
      source: 'स्वामी आनंद स्वरूप जी',
    ),
  ];

  static Quote get todaysQuote {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return quotes[dayOfYear % quotes.length];
  }

  // ------------------------------------------------------------ Pravachans
  static final pravachans = <Pravachan>[
    Pravachan(
      id: 'p1',
      titleHi: 'राष्ट्र रक्षा और धर्म',
      titleEn: 'Nation Protection and Dharma',
      descriptionHi:
      'स्वामी आनंद स्वरूप जी धर्म की रक्षा और एक सशक्त राष्ट्र के निर्माण में युवाओं की भूमिका पर प्रकाश डालते हैं।',
      descriptionEn:
      'Swami Anand Swaroop ji highlights the role of youth in protecting dharma and building a strong nation.',
      imageUrl: _swamiPortrait,
      // ▼▼▼ APNA YOUTUBE VIDEO YAHAN DAALO ▼▼▼
      // YouTube link: https://www.youtube.com/watch?v=XXXXXXXXXXX
      //           ya: https://youtu.be/XXXXXXXXXXX
      // 'v=' ke baad ya 'youtu.be/' ke baad ka 11-character code = youtubeId.
      // Niche 'Ybb5GZuJYAo' ki jagah apne pravachan ki ID daal do.
      youtubeId: 'zyzSqxKWnck',
      durationMin: 45,
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Pravachan(
      id: 'p2',
      titleHi: 'गंगा सेवा संकल्प',
      titleEn: 'Ganga Seva Resolution',
      descriptionHi:
      '१८ वर्षों से अधिक समय गंगा की सफाई और नदियों के पुनरुद्धार के लिए समर्पित।',
      descriptionEn:
      'Over 18 years dedicated to cleaning the Ganga and river rejuvenation.',
      imageUrl: _gangaBg,
      // ▼▼▼ APNA YOUTUBE VIDEO YAHAN DAALO ▼▼▼  (ID badlo)
      youtubeId: 'I2dsMXSXhEg',
      durationMin: 38,
      date: DateTime.now().subtract(const Duration(days: 6)),
    ),
  ];

  // --------------------------------------------------------------- Bhajans
  static final bhajans = <Bhajan>[
    Bhajan(
      id: 'b1',
      titleHi: 'ॐ जय जगदीश हरे',
      titleEn: 'Om Jai Jagdish Hare',
      singerHi: 'शांभवी पीठ भजन मंडली',
      singerEn: 'Shambhavi Peeth Bhajan Mandali',
      imageUrl: _swamiPortrait,
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      durationSec: 312,
    ),
    Bhajan(
      id: 'b2',
      titleHi: 'गंगा आरती',
      titleEn: 'Ganga Aarti',
      singerHi: 'शांभवी पीठ भजन मंडली',
      singerEn: 'Shambhavi Peeth Bhajan Mandali',
      imageUrl: _gangaBg,
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      durationSec: 287,
    ),
  ];

  // ---------------------------------------------------------------- Events
  static final events = <EventItem>[
    EventItem(
      id: 'e1',
      titleHi: 'कन्या विवाह महोत्सव',
      titleEn: 'Kanya Vivah Mahotsav',
      venueHi: 'शांभवी मठ, बलिया',
      venueEn: 'Shambhavi Math, Ballia',
      imageUrl: _meditationBg,
      date: DateTime.now().add(const Duration(days: 15)),
    ),
  ];

  // ----------------------------------------------------------------- Books
  static final books = <Book>[
    Book(
      id: 'k1',
      titleHi: 'सनातन वैदिक धर्म',
      titleEn: 'Sanatan Vedic Dharma',
      summaryHi: 'सनातन धर्म के प्रचार और महत्व पर स्वामी जी के विचार।',
      summaryEn: 'Swami ji\'s thoughts on the importance of Sanatan Dharma.',
      imageUrl: _spiritualBg,
      pages: 210,
    ),
  ];

  // --------------------------------------------------------------- Gallery
  static final gallery = <GalleryImage>[
    GalleryImage(url: _swamiPortrait, captionHi: 'स्वामी जी', captionEn: 'Swami Ji'),
    GalleryImage(url: _gauSeva, captionHi: 'गौ सेवा', captionEn: 'Gau Seva'),
    GalleryImage(url: _gangaBg, captionHi: 'गंगा सेवा', captionEn: 'Ganga Seva'),
    GalleryImage(url: _eventBg, captionHi: 'कन्यादान महायज्ञ', captionEn: 'Kanyadan Mahayagya'),
    GalleryImage(url: _annadaan, captionHi: 'अन्नदान सेवा', captionEn: 'Annadaan Seva'),
    GalleryImage(url: _education, captionHi: 'अनाथ शिक्षा', captionEn: 'Orphan Education'),
    GalleryImage(url: _village, captionHi: 'ग्राम विकास', captionEn: 'Village Development'),
    GalleryImage(url: _math, captionHi: 'शांभवी मठ', captionEn: 'Shambhavi Math'),
    GalleryImage(url: _swamiBanner, captionHi: 'शांभवी पीठ', captionEn: 'Shambhavi Peeth'),
  ];

  // --------------------------------------------------------- Seva Karya
  // Shambhavi Peeth ke mukhya seva-kshetra (home screen par dikhte hain).
  static final sevaKaryas = <SevaKarya>[
    const SevaKarya(
      titleHi: 'गौ सेवा',
      titleEn: 'Gau Seva',
      descHi: 'श्री शांभवी गौशाला में गौ-संरक्षण एवं सेवा।',
      descEn: 'Cow protection and care at Shri Shambhavi Gaushala.',
      imageUrl: _gauSeva,
    ),
    const SevaKarya(
      titleHi: 'अनाथ शिक्षा',
      titleEn: 'Orphan Education',
      descHi: 'अनाथ बच्चों हेतु निःशुल्क शिक्षा एवं गुरुकुल — शांभवी मिशन।',
      descEn: 'Free education and gurukul for orphan children — Shambhavi Mission.',
      imageUrl: _education,
    ),
    const SevaKarya(
      titleHi: 'अन्नदान',
      titleEn: 'Annadaan',
      descHi: 'माँ अन्नपूर्णा रसोई — प्रतिदिन निर्धनों हेतु भोजन सेवा।',
      descEn: 'Maa Annapurna Rasoi — daily meal service for the needy.',
      imageUrl: _annadaan,
    ),
    const SevaKarya(
      titleHi: 'गंगा सेवा',
      titleEn: 'Ganga Seva',
      descHi: 'अविरल गंगा, निर्मल गंगा — नदी स्वच्छता एवं पुनरुद्धार।',
      descEn: 'Aviral Ganga, Nirmal Ganga — river cleaning and rejuvenation.',
      imageUrl: _gangaBg,
    ),
    const SevaKarya(
      titleHi: 'कन्या विवाह',
      titleEn: 'Kanya Vivah',
      descHi: 'कन्यादान महायज्ञ — निर्धन कन्याओं का सामूहिक विवाह।',
      descEn: 'Kanyadan Mahayagya — group weddings for underprivileged girls.',
      imageUrl: _eventBg,
    ),
    const SevaKarya(
      titleHi: 'ग्राम विकास',
      titleEn: 'Village Development',
      descHi: 'सलेमपुर 71 — एक संकल्प, एक नई पहचान।',
      descEn: 'Salempur 71 — one resolve, a new identity.',
      imageUrl: _village,
    ),
    const SevaKarya(
      titleHi: 'शांभवी मठ',
      titleEn: 'Shambhavi Math',
      descHi: 'शांभवी मठ एवं केंद्र — साधना एवं सत्संग का पावन स्थल।',
      descEn: 'Shambhavi Math & Centre — a sacred place of sadhana and satsang.',
      imageUrl: _math,
    ),
  ];

  static final heroImage = _swamiBanner;

  // ---------------------------------------------------------------- Social Links
  static const String facebookUrl = 'https://facebook.com/swamianandswaroopofficial';
  static const String youtubeUrl = 'https://youtube.com/@swamianandswaroop';
  static const String instagramUrl = 'https://instagram.com/swamianandswaroop';
  static const String twitterUrl = 'https://twitter.com/swamianand';
  static const String whatsappUrl = 'https://wa.me/919415250000';
}
