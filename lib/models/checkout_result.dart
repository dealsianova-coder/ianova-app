class CheckoutResult {
  const CheckoutResult({
    required this.orderId,
    required this.subtotal,
    required this.delivery,
    required this.total,
    required this.status,
  });

  final int orderId;
  final double subtotal;
  final double delivery;
  final double total;
  final String status;

  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    return CheckoutResult(
      orderId: int.tryParse(json['id'].toString()) ?? 0,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0,
      delivery: double.tryParse(json['delivery'].toString()) ?? 0,
      total: double.tryParse(json['total'].toString()) ?? 0,
      status: json['status']?.toString() ?? 'pending',
    );
  }
}
