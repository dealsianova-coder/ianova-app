class UserAddress {
  const UserAddress({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.address,
    required this.isDefault,
  });

  final int id;
  final String label;
  final String recipientName;
  final String phone;
  final String address;
  final bool isDefault;

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: int.tryParse(json['id'].toString()) ?? 0,
      label: json['label']?.toString() ?? '',
      recipientName: json['recipient_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      isDefault: json['is_default'] == true ||
          json['is_default'].toString() == '1',
    );
  }
}
