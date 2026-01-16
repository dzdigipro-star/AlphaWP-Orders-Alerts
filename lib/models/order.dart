class Order {
  final int id;
  final String orderNumber;
  final String status;
  final DateTime? dateCreated;
  final double total;
  final double subtotal;
  final double shippingTotal;
  final String currency;
  final String customerName;
  final String customerPhone;
  final String customerCity;
  final String customerState;
  final String paymentMethod;
  final List<OrderItem>? items;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.dateCreated,
    required this.total,
    required this.subtotal,
    required this.shippingTotal,
    required this.currency,
    required this.customerName,
    required this.customerPhone,
    required this.customerCity,
    required this.customerState,
    required this.paymentMethod,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'],
    orderNumber: json['order_number'].toString(),
    status: json['status'],
    dateCreated: json['date_created'] != null 
        ? DateTime.tryParse(json['date_created']) 
        : null,
    total: (json['total'] as num).toDouble(),
    subtotal: (json['subtotal'] as num).toDouble(),
    shippingTotal: (json['shipping_total'] as num).toDouble(),
    currency: json['currency'] ?? 'DZD',
    customerName: json['customer_name'] ?? '',
    customerPhone: json['customer_phone'] ?? '',
    customerCity: json['customer_city'] ?? '',
    customerState: json['customer_state'] ?? '',
    paymentMethod: json['payment_method'] ?? '',
    items: json['items'] != null 
        ? (json['items'] as List).map((i) => OrderItem.fromJson(i)).toList()
        : null,
  );

  String get statusDisplay {
    switch (status) {
      case 'pending': return 'Pending';
      case 'processing': return 'Processing';
      case 'on-hold': return 'On Hold';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      case 'refunded': return 'Refunded';
      case 'failed': return 'Failed';
      default: return status;
    }
  }

  String get statusEmoji {
    switch (status) {
      case 'pending': return '⏳';
      case 'processing': return '📦';
      case 'on-hold': return '⏸️';
      case 'completed': return '✅';
      case 'cancelled': return '❌';
      case 'refunded': return '↩️';
      case 'failed': return '⚠️';
      default: return '📋';
    }
  }
}

class OrderItem {
  final int id;
  final String name;
  final int quantity;
  final double total;
  final int productId;
  final String? image;

  OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.total,
    required this.productId,
    this.image,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: json['id'],
    name: json['name'],
    quantity: json['quantity'],
    total: (json['total'] as num).toDouble(),
    productId: json['product_id'],
    image: json['image'],
  );
}
