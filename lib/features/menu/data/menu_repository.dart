import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/product.dart';
import '../domain/section.dart';

class MenuRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  Future<List<Section>> getSections() async {
    if (!_supabase.isInitialized) {
      return _fallbackSections;
    }
    try {
      final res = await _supabase.client
          .from('sections')
          .select()
          .order('sort_order', ascending: true);
      return (res as List).map((e) => Section.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getSections fallback: $e');
      return _fallbackSections;
    }
  }

  Future<List<Product>> getProducts() async {
    if (!_supabase.isInitialized) {
      return _fallbackProducts;
    }
    try {
      final res = await _supabase.client
          .from('products')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      return (res as List).map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getProducts fallback: $e');
      return _fallbackProducts;
    }
  }

  Future<List<Product>> getAllProductsForOwner() async {
    if (!_supabase.isInitialized) return _fallbackProducts;
    final res = await _supabase.client
        .from('products')
        .select()
        .order('sort_order', ascending: true);
    return (res as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<void> updateProduct(Product product) async {
    if (!_supabase.isInitialized) return;
    await _supabase.client.from('products').update({
      'name': product.name,
      'price': product.price,
      'is_active': product.isActive,
      'is_new': product.isNew,
      'sort_order': product.sortOrder,
    }).eq('id', product.id);
  }

  // Fallback initial seeds if offline or setting up
  static const List<Section> _fallbackSections = [
    Section(id: '11111111-1111-1111-1111-111111111111', name: 'Chocolate Bowl', sortOrder: 1),
    Section(id: '22222222-2222-2222-2222-222222222222', name: 'Waffle', sortOrder: 2),
  ];

  static const List<Product> _fallbackProducts = [
    // Chocolate Bowl
    Product(id: 'c1', sectionId: '11111111-1111-1111-1111-111111111111', name: 'Dark Chocolate Bowl', price: 70, sortOrder: 1, imageKey: 'choc_dark'),
    Product(id: 'c2', sectionId: '11111111-1111-1111-1111-111111111111', name: 'Milk Chocolate Bowl', price: 80, sortOrder: 2, imageKey: 'choc_milk'),
    Product(id: 'c3', sectionId: '11111111-1111-1111-1111-111111111111', name: 'Kit Kat Bowl', price: 90, sortOrder: 3, imageKey: 'choc_kitkat'),
    Product(id: 'c4', sectionId: '11111111-1111-1111-1111-111111111111', name: 'Double Chocolate Bowl', price: 80, sortOrder: 4, imageKey: 'choc_double'),
    Product(id: 'c5', sectionId: '11111111-1111-1111-1111-111111111111', name: 'White Chocolate Bowl', price: 100, sortOrder: 5, imageKey: 'choc_white'),
    Product(id: 'c6', sectionId: '11111111-1111-1111-1111-111111111111', name: 'Triple Chocolate Bowl', price: 110, sortOrder: 6, imageKey: 'choc_triple'),
    Product(id: 'c7', sectionId: '11111111-1111-1111-1111-111111111111', name: 'Oreo Bowl', price: 90, sortOrder: 7, imageKey: 'choc_oreo'),
    Product(id: 'c8', sectionId: '11111111-1111-1111-1111-111111111111', name: 'Biscoff Biscuit Bowl', price: 110, sortOrder: 8, imageKey: 'choc_biscoff'),
    Product(id: 'c9', sectionId: '11111111-1111-1111-1111-111111111111', name: 'Strawberry Chocolate Bowl', price: 110, sortOrder: 9, isNew: true, imageKey: 'choc_strawberry'),
    // Waffle
    Product(id: 'w1', sectionId: '22222222-2222-2222-2222-222222222222', name: 'Dark Waffle', price: 60, sortOrder: 1, imageKey: 'waffle_dark'),
    Product(id: 'w2', sectionId: '22222222-2222-2222-2222-222222222222', name: 'Milk Waffle', price: 70, sortOrder: 2, imageKey: 'waffle_milk'),
    Product(id: 'w3', sectionId: '22222222-2222-2222-2222-222222222222', name: 'Kitkat Waffle', price: 80, sortOrder: 3, imageKey: 'waffle_kitkat'),
    Product(id: 'w4', sectionId: '22222222-2222-2222-2222-222222222222', name: 'Double Chocolate Waffle', price: 70, sortOrder: 4, imageKey: 'waffle_double'),
    Product(id: 'w5', sectionId: '22222222-2222-2222-2222-222222222222', name: 'White Waffle', price: 90, sortOrder: 5, imageKey: 'waffle_white'),
    Product(id: 'w6', sectionId: '22222222-2222-2222-2222-222222222222', name: 'Triple Chocolate Waffle', price: 100, sortOrder: 6, imageKey: 'waffle_triple'),
    Product(id: 'w7', sectionId: '22222222-2222-2222-2222-222222222222', name: 'Oreo Waffle', price: 80, sortOrder: 7, imageKey: 'waffle_oreo'),
    Product(id: 'w8', sectionId: '22222222-2222-2222-2222-222222222222', name: 'Biscoff Waffle', price: 100, sortOrder: 8, imageKey: 'waffle_biscoff'),
    Product(id: 'w9', sectionId: '22222222-2222-2222-2222-222222222222', name: 'Waffle with Ice Cream', price: 110, sortOrder: 9, imageKey: 'waffle_icecream'),
    // Flavors sub-group
    Product(id: 'w10', sectionId: '22222222-2222-2222-2222-222222222222', subGroup: 'Waffle with Ice Cream Flavors', name: 'Waffle with Pista Ice Cream', price: 105, sortOrder: 10, imageKey: 'waffle_pista'),
    Product(id: 'w11', sectionId: '22222222-2222-2222-2222-222222222222', subGroup: 'Waffle with Ice Cream Flavors', name: 'Waffle with Chocolate Ice Cream', price: 110, sortOrder: 11, imageKey: 'waffle_chocolate_ic'),
    Product(id: 'w12', sectionId: '22222222-2222-2222-2222-222222222222', subGroup: 'Waffle with Ice Cream Flavors', name: 'Waffle with Kesar Kulfi Ice Cream', price: 110, sortOrder: 12, imageKey: 'waffle_kesar_kulfi'),
    Product(id: 'w13', sectionId: '22222222-2222-2222-2222-222222222222', subGroup: 'Waffle with Ice Cream Flavors', name: 'Waffle with Strawberry Ice Cream', price: 110, sortOrder: 13, imageKey: 'waffle_strawberry_ic'),
  ];
}
