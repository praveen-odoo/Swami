import 'package:flutter/foundation.dart';

class ApiProfile {
  final int? id;
  final String? photo;
  final String? nameHi;
  final String? nameEn;
  final String? politicianHi;
  final String? politicianEn;
  final String? descriptionHi;
  final String? descriptionEn;
  final String? email;
  final String? phone;
  final String? website;
  final String? facebook;
  final String? youtube;
  final String? instagram;
  final String? twitter;
  final String? whatsapp;

  ApiProfile({
    this.id,
    this.photo,
    this.nameHi,
    this.nameEn,
    this.politicianHi,
    this.politicianEn,
    this.descriptionHi,
    this.descriptionEn,
    this.email,
    this.phone,
    this.website,
    this.facebook,
    this.youtube,
    this.instagram,
    this.twitter,
    this.whatsapp,
  });

  factory ApiProfile.fromJson(Map<String, dynamic> json) {
    return ApiProfile(
      id: json['id'] as int?,
      photo: json['logo'] as String?,
      nameHi: json['name_hi'] as String? ?? json['name'] as String?,
      nameEn: json['name_en'] as String? ?? json['name'] as String?,
      politicianHi: json['politician_hi'] as String? ?? json['politician'] as String?,
      politicianEn: json['politician_en'] as String? ?? json['politician'] as String?,
      descriptionHi: json['description_hi'] as String? ?? json['description'] as String?,
      descriptionEn: json['description_en'] as String? ?? json['description'] as String?,
      email: json['contact_email'] as String?,
      phone: json['contact_phone'] as String?,
      website: json['website'] as String?,
      facebook: json['facebook_link'] as String?,
      youtube: json['youtube_link'] as String?,
      instagram: json['instagram_link'] as String?,
      twitter: json['twitter_link'] as String?,
      whatsapp: json['whatsapp_link'] as String?,
    );
  }

  String getName(bool isHindi) => isHindi ? (nameHi ?? '') : (nameEn ?? '');
  String getPolitician(bool isHindi) => isHindi ? (politicianHi ?? '') : (politicianEn ?? '');
  String getDescription(bool isHindi) => isHindi ? (descriptionHi ?? '') : (descriptionEn ?? '');
}

class ApiBanner {
  final int id;
  final String? name;
  final String? image;

  ApiBanner({required this.id, this.name, this.image});

  factory ApiBanner.fromJson(Map<String, dynamic> json) {
    return ApiBanner(
      id: json['id'] as int,
      name: json['name'] as String?,
      image: json['image'] as String?,
    );
  }
}

class ApiNotification {
  final int id;
  final String? nameHi;
  final String? nameEn;
  final String? titleHi;
  final String? titleEn;
  final String? descriptionHi;
  final String? descriptionEn;
  final String? image;
  final String? type;

  ApiNotification({
    required this.id, 
    this.nameHi,
    this.nameEn,
    this.titleHi,
    this.titleEn,
    this.descriptionHi,
    this.descriptionEn,
    this.image,
    this.type,
  });

  factory ApiNotification.fromJson(Map<String, dynamic> json) {
    String s(dynamic val) {
      if (val == null) return '';
      String str = val.toString();
      return str.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    return ApiNotification(
      id: json['id'] as int,
      nameHi: s(json['name_hi'] ?? json['name']),
      nameEn: s(json['name_en'] ?? json['name']),
      titleHi: s(json['short_description_hi'] ?? json['short_description'] ?? json['title_hi'] ?? json['title'] ?? json['name']),
      titleEn: s(json['short_description_en'] ?? json['short_description'] ?? json['title_en'] ?? json['title'] ?? json['name']),
      descriptionHi: s(json['long_description_hi'] ?? json['long_description'] ?? json['description_hi'] ?? json['description']),
      descriptionEn: s(json['long_description_en'] ?? json['long_description'] ?? json['description_en'] ?? json['description']),
      image: json['image'] as String?,
      type: json['type'] as String?,
    );
  }

  String getName(bool isHindi) => isHindi ? (nameHi ?? '') : (nameEn ?? '');
  String getTitle(bool isHindi) => isHindi ? (titleHi ?? '') : (titleEn ?? '');
  String getDescription(bool isHindi) => isHindi ? (descriptionHi ?? '') : (descriptionEn ?? '');
}

class ApiAnnouncement {
  final int id;
  final String? date;
  final String? dateTo;
  final String? nameHi;
  final String? nameEn;
  final String? titleHi;
  final String? titleEn;
  final String? descriptionHi;
  final String? descriptionEn;
  final String? image;
  final String? type;

  ApiAnnouncement({
    required this.id, 
    this.date, 
    this.dateTo,
    this.nameHi,
    this.nameEn,
    this.titleHi,
    this.titleEn,
    this.descriptionHi,
    this.descriptionEn,
    this.image,
    this.type,
  });

  factory ApiAnnouncement.fromJson(Map<String, dynamic> json) {
    String s(dynamic val) {
      if (val == null) return '';
      String str = val.toString();
      return str.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    return ApiAnnouncement(
      id: json['id'] as int,
      date: json['date'] as String?,
      dateTo: json['date_to'] as String?,
      nameHi: s(json['name_hi'] ?? json['name']),
      nameEn: s(json['name_en'] ?? json['name']),
      titleHi: s(json['short_description_hi'] ?? json['short_description'] ?? json['title_hi'] ?? json['title'] ?? json['name']),
      titleEn: s(json['short_description_en'] ?? json['short_description'] ?? json['title_en'] ?? json['title'] ?? json['name']),
      descriptionHi: s(json['long_description_hi'] ?? json['long_description'] ?? json['description_hi'] ?? json['description']),
      descriptionEn: s(json['long_description_en'] ?? json['long_description'] ?? json['description_en'] ?? json['description']),
      image: json['image'] as String?,
      type: json['type'] as String?,
    );
  }

  String getName(bool isHindi) => isHindi ? (nameHi ?? '') : (nameEn ?? '');
  String getTitle(bool isHindi) => isHindi ? (titleHi ?? '') : (titleEn ?? '');
  String getDescription(bool isHindi) => isHindi ? (descriptionHi ?? '') : (descriptionEn ?? '');

  bool get isNew {
    if (date == null) return false;
    try {
      final eventDate = DateTime.parse(date!);
      final now = DateTime.now();
      if (eventDate.isAfter(now)) return true;
      final difference = now.difference(eventDate).inDays;
      return difference <= 3;
    } catch (_) {
      return false;
    }
  }
}

class ApiThought {
  final int id;
  final String? nameHi;
  final String? nameEn;
  final String? date;
  final String? textHi;
  final String? textEn;
  final String? videoUrl;
  final String? image;

  ApiThought({required this.id, this.nameHi, this.nameEn, this.date, this.textHi, this.textEn, this.videoUrl, this.image});

  factory ApiThought.fromJson(Map<String, dynamic> json) {
    String s(dynamic val) {
      if (val == null) return '';
      String str = val.toString();
      return str.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    return ApiThought(
      id: json['id'] as int,
      nameHi: s(json['name_hi'] ?? json['name']),
      nameEn: s(json['name_en'] ?? json['name']),
      date: json['date'] as String?,
      textHi: s(json['long_description_hi'] ?? json['short_description_hi'] ?? json['description_hi'] ?? json['text_hi'] ?? json['long_description'] ?? json['short_description'] ?? json['description'] ?? json['text']),
      textEn: s(json['long_description_en'] ?? json['short_description_en'] ?? json['description_en'] ?? json['text_en'] ?? json['long_description'] ?? json['short_description'] ?? json['description'] ?? json['text']),
      videoUrl: json['video_url'] as String?,
      image: json['image'] as String?,
    );
  }

  String getName(bool isHindi) => isHindi ? (nameHi ?? '') : (nameEn ?? '');
  String getText(bool isHindi) => isHindi ? (textHi ?? '') : (textEn ?? '');
}

class ApiHomeData {
  final ApiProfile? profile;
  final List<ApiBanner> banners;
  final List<ApiNotification> notifications;
  final List<ApiAnnouncement> announcements;
  final List<ApiThought> thoughts;
  final List<ApiProfile> users;

  ApiHomeData({
    this.profile,
    this.banners = const [],
    this.notifications = const [],
    this.announcements = const [],
    this.thoughts = const [],
    this.users = const [],
  });

  factory ApiHomeData.fromJson(Map<String, dynamic> json) {
    debugPrint('⚙️ [Parser] Parsing ApiHomeData');
    
    dynamic dataRaw = json['data'];
    Map<String, dynamic> data = {};
    
    if (dataRaw is Map<String, dynamic>) {
      data = dataRaw;
    } else {
      debugPrint('⚠️ [Parser] "data" missing or not a map');
    }

    final thoughtsList = data['thoughts'] ?? data['thaughts'] ?? [];
    final announcementsList = data['announcements'] ?? [];
    final notificationsList = data['notifications'] ?? [];
    final bannersList = data['banners'] ?? [];
    final usersList = data['users'] ?? data['members'] ?? data['community'] ?? [];

    return ApiHomeData(
      profile: data['profile'] != null ? ApiProfile.fromJson(data['profile'] as Map<String, dynamic>) : null,
      banners: (bannersList is List) ? bannersList.map((e) => ApiBanner.fromJson(e as Map<String, dynamic>)).toList() : [],
      notifications: (notificationsList is List) ? notificationsList.map((e) => ApiNotification.fromJson(e as Map<String, dynamic>)).toList() : [],
      announcements: (announcementsList is List) ? announcementsList.map((e) => ApiAnnouncement.fromJson(e as Map<String, dynamic>)).toList() : [],
      thoughts: (thoughtsList is List) ? thoughtsList.map((e) => ApiThought.fromJson(e as Map<String, dynamic>)).toList() : [],
      users: (usersList is List) ? usersList.map((e) => ApiProfile.fromJson(e as Map<String, dynamic>)).toList() : [],
    );
  }
}
