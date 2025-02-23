class Dish {
  final String? id;
  String dishName, imgPath, category;
  List<String> ingredients, subCategories;
  double price, discount;

  Dish({
    this.id,
    required this.dishName,
    required this.imgPath,
    required this.ingredients,
    String? category,
    List<String>? subCategories,
    required this.price,
    double? discount,
  }) : category = category ?? '',
       subCategories = subCategories ?? [],
       discount = discount ?? 0;

  factory Dish.toObject(String docId, Map<String, dynamic> doc) {
    return Dish(
      id: docId,
      dishName: doc['dishName'],
      imgPath: doc['imgPath'],
      ingredients: List<String>.from(doc['ingredients']),
      category: doc['category'],
      subCategories: List<String>.from(doc['subCategories']),
      price: doc['price'].toDouble(),
      discount: doc['discount'].toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dishName': dishName,
      'imgPath': imgPath,
      'ingredients': ingredients,
      'category': category,
      'subCategories': subCategories,
      'price': price,
      'discount': discount,
    };
  }

  @override
  String toString() {
    return 'Dish{id: $id, dishName: $dishName, imgPath: $imgPath, category: $category, ingredients: $ingredients, subCategories: $subCategories, price: $price, discount: $discount}';
  }
}
