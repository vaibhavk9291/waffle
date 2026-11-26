class ShopSettings {
  final int id;
  final String shopName;
  final String address;
  final String phone;
  final String? gstin;
  final String receiptFooter;
  final int paperWidthMm;

  const ShopSettings({
    required this.id,
    required this.shopName,
    required this.address,
    required this.phone,
    this.gstin,
    required this.receiptFooter,
    required this.paperWidthMm,
  });

  factory ShopSettings.defaultSettings() => const ShopSettings(
        id: 1,
        shopName: 'Shrimant Street Food',
        address: 'Shop No. 1, Main Road, Pune',
        phone: '+91 9876543210',
        gstin: null,
        receiptFooter: 'Thank you! Visit again.',
        paperWidthMm: 58,
      );

  factory ShopSettings.fromJson(Map<String, dynamic> json) {
    return ShopSettings(
      id: (json['id'] as num?)?.toInt() ?? 1,
      shopName: json['shop_name'] as String? ?? 'Shrimant Street Food',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      gstin: json['gstin'] as String?,
      receiptFooter: json['receipt_footer'] as String? ?? 'Thank you! Visit again.',
      paperWidthMm: (json['paper_width_mm'] as num?)?.toInt() ?? 58,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shop_name': shopName,
        'address': address,
        'phone': phone,
        'gstin': gstin,
        'receipt_footer': receiptFooter,
        'paper_width_mm': paperWidthMm,
      };
}
