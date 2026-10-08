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
    );
  }
}
