class SellerSession {
  const SellerSession({
    required this.token,
    required this.businessName,
    required this.email,
    required this.status,
  });

  final String token;
  final String businessName;
  final String email;
  final String status;

  SellerSession copyWith({String? businessName, String? status}) {
    return SellerSession(
      token: token,
      businessName: businessName ?? this.businessName,
      email: email,
      status: status ?? this.status,
    );
  }
}

class SellerMessage {
  const SellerMessage({
    required this.id,
    required this.fromAdmin,
    required this.body,
    required this.createdAt,
  });

  final int id;
  final bool fromAdmin;
  final String body;
  final DateTime? createdAt;

  factory SellerMessage.fromJson(Map<String, dynamic> json) {
    return SellerMessage(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      fromAdmin: json['sender']?.toString() == 'admin',
      body: json['body']?.toString() ?? '',
      createdAt: DateTime.tryParse(
        (json['created_at']?.toString() ?? '').replaceFirst(' ', 'T'),
      ),
    );
  }
}

class SellerThread {
  const SellerThread({
    required this.businessName,
    required this.status,
    required this.messages,
  });

  final String businessName;
  final String status;
  final List<SellerMessage> messages;
}
