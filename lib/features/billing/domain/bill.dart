class BillItem {
  final String id;
  final String billId;
  final String? productId;
  final String productName;
  final int unitPrice;
  final int qty;
  final int lineTotal;

  const BillItem({
    required this.id,
    required this.billId,
    this.productId,
    required this.productName,
    required this.unitPrice,
    required this.qty,
    required this.lineTotal,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      id: json['id'] as String? ?? '',
      billId: json['bill_id'] as String? ?? '',
      productId: json['product_id'] as String?,
      productName: json['product_name'] as String? ?? '',
      unitPrice: (json['unit_price'] as num?)?.toInt() ?? 0,
      qty: (json['qty'] as num?)?.toInt() ?? 1,
      lineTotal: (json['line_total'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bill_id': billId,
        'product_id': productId,
        'product_name': productName,
        'unit_price': unitPrice,
        'qty': qty,
        'line_total': lineTotal,
      };
}

class Bill {
  final String id;
  final int billNo;
  final String businessDate;
  final int subtotal;
  final int discount;
  final int total;
  final String paymentMode; // 'cash' | 'upi'
  final String status; // 'paid' | 'void'
  final String? voidReason;
  final String? createdBy;
  final DateTime createdAt;
  final List<BillItem> items;

  const Bill({
    required this.id,
    required this.billNo,
    required this.businessDate,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paymentMode,
    required this.status,
    this.voidReason,
    this.createdBy,
    required this.createdAt,
    this.items = const [],
  });

  bool get isVoid => status == 'void';

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String,
      billNo: (json['bill_no'] as num?)?.toInt() ?? 0,
      businessDate: json['business_date'] as String? ?? '',
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      discount: (json['discount'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      paymentMode: json['payment_mode'] as String? ?? 'cash',
      status: json['status'] as String? ?? 'paid',
      voidReason: json['void_reason'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      items: (json['bill_items'] as List<dynamic>?)
              ?.map((e) => BillItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bill_no': billNo,
        'business_date': businessDate,
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'payment_mode': paymentMode,
        'status': status,
        'void_reason': voidReason,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
      };
}
