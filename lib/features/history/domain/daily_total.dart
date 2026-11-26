class DailyTotal {
  final String businessDate;
  final int billsCount;
  final int itemsSold;
  final int grossRevenue;
  final int totalDiscount;
  final int expensesTotal;
  final int net;

  const DailyTotal({
    required this.businessDate,
    required this.billsCount,
    required this.itemsSold,
    required this.grossRevenue,
    required this.totalDiscount,
    required this.expensesTotal,
    required this.net,
  });

  factory DailyTotal.empty(String date) => DailyTotal(
        businessDate: date,
        billsCount: 0,
        itemsSold: 0,
        grossRevenue: 0,
        totalDiscount: 0,
        expensesTotal: 0,
        net: 0,
      );

  factory DailyTotal.fromJson(Map<String, dynamic> json) {
    return DailyTotal(
      businessDate: json['business_date']?.toString() ?? '',
      billsCount: (json['bills_count'] as num?)?.toInt() ?? 0,
      itemsSold: (json['items_sold'] as num?)?.toInt() ?? 0,
      grossRevenue: (json['gross_revenue'] as num?)?.toInt() ?? 0,
      totalDiscount: (json['total_discount'] as num?)?.toInt() ?? 0,
      expensesTotal: (json['expenses_total'] as num?)?.toInt() ?? 0,
      net: (json['net'] as num?)?.toInt() ?? 0,
    );
  }

  DailyTotal copyWith({
    String? businessDate,
    int? billsCount,
    int? itemsSold,
    int? grossRevenue,
    int? totalDiscount,
    int? expensesTotal,
    int? net,
  }) {
    return DailyTotal(
      businessDate: businessDate ?? this.businessDate,
      billsCount: billsCount ?? this.billsCount,
      itemsSold: itemsSold ?? this.itemsSold,
      grossRevenue: grossRevenue ?? this.grossRevenue,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      expensesTotal: expensesTotal ?? this.expensesTotal,
      net: net ?? this.net,
    );
  }
}
