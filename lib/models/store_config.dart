class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.image,
    required this.linkType,
    required this.linkValue,
    required this.color,
  });

  final int id;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final String image;
  final String linkType;
  final String linkValue;
  final String color;

  factory HomeBanner.fromJson(Map<String, dynamic> json) {
    return HomeBanner(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      buttonLabel: json['button_label']?.toString() ?? 'Shop now',
      image: json['image']?.toString() ?? '',
      linkType: json['link_type']?.toString() ?? 'none',
      linkValue: json['link_value']?.toString() ?? '',
      color: json['color']?.toString() ?? 'blush',
    );
  }
}

/// Admin-controlled video ad that interrupts the hero carousel on a timer.
class VideoAdConfig {
  const VideoAdConfig({
    this.enabled = false,
    this.src = '',
    this.intervalMinutes = 3,
    this.minSeconds = 30,
    this.linkType = 'none',
    this.linkValue = '',
  });

  final bool enabled;
  final String src;
  final int intervalMinutes;
  final int minSeconds;
  final String linkType;
  final String linkValue;

  /// True only when there's actually a video configured and switched on.
  bool get isActive => enabled && src.trim().isNotEmpty;

  bool get hasLink => linkType != 'none' && linkValue.trim().isNotEmpty;

  static const defaults = VideoAdConfig();

  factory VideoAdConfig.fromJson(Map<String, dynamic> json) {
    bool flag(dynamic value, bool fallback) {
      if (value is bool) return value;
      if (value == null) return fallback;
      return value.toString() != '0' && value.toString() != 'false';
    }

    return VideoAdConfig(
      enabled: flag(json['enabled'], false),
      src: json['src']?.toString() ?? '',
      intervalMinutes:
          int.tryParse(json['interval_minutes']?.toString() ?? '') ?? 3,
      minSeconds: int.tryParse(json['min_seconds']?.toString() ?? '') ?? 30,
      linkType: json['link_type']?.toString() ?? 'none',
      linkValue: json['link_value']?.toString() ?? '',
    );
  }
}

/// Front-store settings the admin controls (flash deals, sections, announcement).
class StoreConfig {
  const StoreConfig({
    this.flashActive = true,
    this.flashEndsAt,
    this.flashTitle = 'Flash deals',
    this.showSale = true,
    this.showCategories = true,
    this.showRecent = true,
    this.showPopular = true,
    this.announcement = '',
    this.supportPhone = '',
    this.supportEmail = '',
    this.banners = const [],
    this.videoAd = VideoAdConfig.defaults,
  });

  final bool flashActive;
  final DateTime? flashEndsAt;
  final String flashTitle;
  final bool showSale;
  final bool showCategories;
  final bool showRecent;
  final bool showPopular;
  final String announcement;
  final String supportPhone;
  final String supportEmail;
  final List<HomeBanner> banners;
  final VideoAdConfig videoAd;

  static const defaults = StoreConfig();

  factory StoreConfig.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> section(String key) {
      final value = json[key];
      return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
    }

    bool flag(Map<String, dynamic> map, String key, bool fallback) {
      final value = map[key];
      if (value is bool) return value;
      if (value == null) return fallback;
      return value.toString() != '0' && value.toString() != 'false';
    }

    final flash = section('flash');
    final sections = section('sections');
    final announcement = section('announcement');
    final support = section('support');
    final endsRaw = flash['ends_at']?.toString();
    final text = announcement['text']?.toString().trim() ?? '';
    final rawBanners = json['banners'];
    final banners = rawBanners is List
        ? rawBanners
            .whereType<Map>()
            .map((item) => HomeBanner.fromJson(Map<String, dynamic>.from(item)))
            .where((banner) => banner.title.isNotEmpty)
            .toList()
        : <HomeBanner>[];

    final rawVideoAd = json['video_ad'];
    final videoAd = rawVideoAd is Map
        ? VideoAdConfig.fromJson(Map<String, dynamic>.from(rawVideoAd))
        : VideoAdConfig.defaults;

    return StoreConfig(
      flashActive: flag(flash, 'active', true),
      flashEndsAt: endsRaw == null ? null : DateTime.tryParse(endsRaw)?.toLocal(),
      flashTitle: (flash['title']?.toString().trim().isNotEmpty ?? false)
          ? flash['title'].toString().trim()
          : 'Flash deals',
      showSale: flag(sections, 'sale', true),
      showCategories: flag(sections, 'categories', true),
      showRecent: flag(sections, 'recent', true),
      showPopular: flag(sections, 'popular', true),
      announcement: flag(announcement, 'enabled', false) ? text : '',
      supportPhone: support['phone']?.toString().trim() ?? '',
      supportEmail: support['email']?.toString().trim() ?? '',
      banners: banners,
      videoAd: videoAd,
    );
  }
}
