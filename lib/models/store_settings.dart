class TrustPoint {
  const TrustPoint({
    required this.key,
    required this.title,
    required this.text,
  });

  final String key;
  final String title;
  final String text;

  factory TrustPoint.fromJson(Map<String, dynamic> json) {
    return TrustPoint(
      key: json['key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
    );
  }
}

/// Delivery and trust information the store owner edits in the admin.
class StoreSettings {
  const StoreSettings({
    required this.freeDeliveryThreshold,
    required this.deliveryFee,
    required this.trust,
    this.depositPct = 0,
    this.payInstructions = '',
  });

  final double freeDeliveryThreshold;
  final double deliveryFee;
  final List<TrustPoint> trust;
  final double depositPct;
  final String payInstructions;

  factory StoreSettings.fromJson(Map<String, dynamic> json) {
    final trust = json['trust'];

    return StoreSettings(
      freeDeliveryThreshold:
          double.tryParse(json['free_delivery_threshold'].toString()) ?? 0,
      deliveryFee: double.tryParse(json['delivery_fee'].toString()) ?? 0,
      depositPct: double.tryParse('${json['deposit_pct']}') ?? 0,
      payInstructions: json['pay_instructions']?.toString() ?? '',
      trust: trust is List
          ? trust
              .whereType<Map>()
              .map(
                (item) => TrustPoint.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const [],
    );
  }
}
