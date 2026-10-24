class CheckoutResult {
  const CheckoutResult({
    required this.orderId,
    required this.subtotal,
    required this.delivery,
    required this.total,
    required this.status,
    this.payPlan = 'full',
    this.depositPct = 0,
    this.depositDue = 0,
    this.payInstructions = '',
    this.discount = 0,
  });

  final int orderId;
  final double subtotal;
  final double delivery;
  final double total;
  final String status;
  final String payPlan;
  final double depositPct;
  final double depositDue;
  final String payInstructions;
  final double discount;

  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    return CheckoutResult(
      orderId: int.tryParse(json['id'].toString()) ?? 0,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0,
      delivery: double.tryParse(json['delivery'].toString()) ?? 0,
      total: double.tryParse(json['total'].toString()) ?? 0,
      status: json['status']?.toString() ?? 'pending',
      payPlan: json['pay_plan']?.toString() ?? 'full',
      depositPct: double.tryParse('${json['deposit_pct']}') ?? 0,
      depositDue: double.tryParse('${json['deposit_due']}') ?? 0,
      payInstructions: json['pay_instructions']?.toString() ?? '',
      discount: double.tryParse('${json['discount']}') ?? 0,
    );
  }
}

/// What a coupon would take off the current cart (from api/coupon_check.php).
class CouponPreview {
  const CouponPreview({
    required this.code,
    required this.label,
    required this.message,
    required this.discount,
    required this.total,
  });

  final String code;
  final String label;
  final String message;
  final double discount;
  final double total;

  factory CouponPreview.fromJson(Map<String, dynamic> json) {
    return CouponPreview(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      discount: double.tryParse('${json['discount']}') ?? 0,
      total: double.tryParse('${json['total']}') ?? 0,
    );
  }
}
