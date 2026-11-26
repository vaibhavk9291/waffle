import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../menu/domain/product.dart';
import '../domain/cart_item.dart';

class CartState {
  final Map<String, CartItem> items; // keyed by product.id

  const CartState({this.items = const {}});

  List<CartItem> get itemList => items.values.toList();
  int get totalItemsCount => items.values.fold(0, (sum, i) => sum + i.qty);
  int get subtotal => items.values.fold(0, (sum, i) => sum + i.lineTotal);

  int getQuantity(String productId) => items[productId]?.qty ?? 0;

  CartState copyWith({Map<String, CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addItem(Product product) {
    final updated = Map<String, CartItem>.from(state.items);
    if (updated.containsKey(product.id)) {
      final current = updated[product.id]!;
      updated[product.id] = current.copyWith(qty: current.qty + 1);
    } else {
      updated[product.id] = CartItem(product: product, qty: 1);
    }
    state = state.copyWith(items: updated);
  }

  void removeItem(Product product) {
    final updated = Map<String, CartItem>.from(state.items);
    if (!updated.containsKey(product.id)) return;

    final current = updated[product.id]!;
    if (current.qty > 1) {
      updated[product.id] = current.copyWith(qty: current.qty - 1);
    } else {
      updated.remove(product.id);
    }
    state = state.copyWith(items: updated);
  }

  void setQuantity(Product product, int qty) {
    final updated = Map<String, CartItem>.from(state.items);
    if (qty <= 0) {
      updated.remove(product.id);
    } else {
      updated[product.id] = CartItem(product: product, qty: qty);
    }
    state = state.copyWith(items: updated);
  }

  void clearCart() {
    state = const CartState();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
