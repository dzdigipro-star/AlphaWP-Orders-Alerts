class Lead {
  final int id;
  final DateTime? time;
  final int productId;
  final String productName;
  final String customerName;
  final String customerPhone;
  final String customerState;
  final String customerCity;
  final String status;
  final int? orderId;

  Lead({
    required this.id,
    this.time,
    required this.productId,
    required this.productName,
    required this.customerName,
    required this.customerPhone,
    required this.customerState,
    required this.customerCity,
    required this.status,
    this.orderId,
  });

  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
    id: json['id'],
    time: json['time'] != null ? DateTime.tryParse(json['time']) : null,
    productId: json['product_id'],
    productName: json['product_name'] ?? '',
    customerName: json['customer_name'] ?? '',
    customerPhone: json['customer_phone'] ?? '',
    customerState: json['customer_state'] ?? '',
    customerCity: json['customer_city'] ?? '',
    status: json['status'] ?? 'abandoned',
    orderId: json['order_id'],
  );

  String get statusDisplay {
    switch (status) {
      case 'abandoned': return 'Abandoned';
      case 'recovered': return 'Recovered';
      case 'captcha_failed': return 'Captcha Failed';
      case 'trash': return 'Trashed';
      default: return status;
    }
  }

  String get statusEmoji {
    switch (status) {
      case 'abandoned': return '⚠️';
      case 'recovered': return '✅';
      case 'captcha_failed': return '🤖';
      case 'trash': return '🗑️';
      default: return '📋';
    }
  }
}
