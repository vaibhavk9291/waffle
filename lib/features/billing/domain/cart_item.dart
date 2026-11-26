import 'package:shrimant/features/menu/domain/product.dart';

class CartItem {
  final Product product;
  final int qty;

  const CartItem({
    required this.product,
    required this.qty,
  });

  int get lineTotal => product.price * qty;

  CartItem copyWith({
    Product? product,
    int? qty,
  }) {
    return CartItem(
      product: product ?? this.product,
      qty: qty ?? this.qty,
    );
  }
}
