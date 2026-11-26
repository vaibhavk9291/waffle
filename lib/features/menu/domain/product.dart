class Product {
  final String id;
  final String sectionId;
  final String? subGroup;
  final String name;
  final int price;
  final int sortOrder;
  final bool isActive;
  final bool isNew;
  final String? imageKey;

  const Product({
    required this.id,
    required this.sectionId,
    this.subGroup,
    required this.name,
    required this.price,
    required this.sortOrder,
    this.isActive = true,
    this.isNew = false,
    this.imageKey,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      sectionId: json['section_id'] as String,
      subGroup: json['sub_group'] as String?,
      name: json['name'] as String,
      price: (json['price'] as num).toInt(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      isNew: json['is_new'] as bool? ?? false,
      imageKey: json['image_key'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'section_id': sectionId,
        'sub_group': subGroup,
        'name': name,
        'price': price,
        'sort_order': sortOrder,
        'is_active': isActive,
        'is_new': isNew,
        'image_key': imageKey,
      };

  Product copyWith({
    String? id,
    String? sectionId,
    String? subGroup,
    String? name,
    int? price,
    int? sortOrder,
    bool? isActive,
    bool? isNew,
    String? imageKey,
  }) {
    return Product(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      subGroup: subGroup ?? this.subGroup,
      name: name ?? this.name,
      price: price ?? this.price,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      isNew: isNew ?? this.isNew,
      imageKey: imageKey ?? this.imageKey,
    );
  }

  String get resolvedImageKey {
    if (imageKey != null && imageKey!.isNotEmpty) return imageKey!;
    final n = name.toLowerCase();
    if (n.contains('strawberry') && (n.contains('bowl') || n.contains('choc'))) return 'choc_strawberry';
    if (n.contains('dark') && (n.contains('bowl') || n.contains('choc'))) return 'choc_dark';
    if (n.contains('milk') && (n.contains('bowl') || n.contains('choc'))) return 'choc_milk';
    if (n.contains('kit') && n.contains('bowl')) return 'choc_kitkat';
    if (n.contains('double') && (n.contains('bowl') || n.contains('choc'))) return 'choc_double';
    if (n.contains('white') && (n.contains('bowl') || n.contains('choc'))) return 'choc_white';
    if (n.contains('triple') && (n.contains('bowl') || n.contains('choc'))) return 'choc_triple';
    if (n.contains('oreo') && n.contains('bowl')) return 'choc_oreo';
    if (n.contains('biscoff') && n.contains('bowl')) return 'choc_biscoff';

    if (n.contains('pista')) return 'waffle_pista';
    if (n.contains('chocolate') && n.contains('ice cream')) return 'waffle_chocolate_ic';
    if (n.contains('kesar')) return 'waffle_kesar_kulfi';
    if (n.contains('strawberry') && n.contains('ice cream')) return 'waffle_strawberry_ic';
    if (n.contains('ice cream')) return 'waffle_icecream';
    if (n.contains('dark') && n.contains('waffle')) return 'waffle_dark';
    if (n.contains('milk') && n.contains('waffle')) return 'waffle_milk';
    if (n.contains('kitkat')) return 'waffle_kitkat';
    if (n.contains('double') && n.contains('waffle')) return 'waffle_double';
    if (n.contains('white') && n.contains('waffle')) return 'waffle_white';
    if (n.contains('triple') && n.contains('waffle')) return 'waffle_triple';
    if (n.contains('oreo') && n.contains('waffle')) return 'waffle_oreo';
    if (n.contains('biscoff') && n.contains('waffle')) return 'waffle_biscoff';
    return 'waffle_dark';
  }
}
