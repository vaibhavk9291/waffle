class CurrencyFormatter {
  CurrencyFormatter._();

  /// Format price with Indian Rupee symbol and no decimals as specified in DESIGN.md
  static String format(int amount) {
    return '₹$amount';
  }
}
