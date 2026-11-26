class Expense {
  final String id;
  final String businessDate;
  final String note;
  final int amount;
  final String? createdBy;
  final DateTime createdAt;
  final bool isDeleted;

  const Expense({
    required this.id,
    required this.businessDate,
    required this.note,
    required this.amount,
    this.createdBy,
    required this.createdAt,
    this.isDeleted = false,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      businessDate: json['business_date'] as String? ?? '',
      note: json['note'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_date': businessDate,
        'note': note,
        'amount': amount,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'is_deleted': isDeleted,
      };
}
