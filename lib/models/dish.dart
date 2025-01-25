class Dish {
  final String? _id;
  final String _dishName, _imgPath;
  final List<String> _ingredients;
  final double _price;

  Dish({
    String? id,
    required String imgPath,
    required String dishName,
    required List<String> ingredients,
    required double price,
  })  : _price = price,
        _ingredients = ingredients,
        _imgPath = imgPath,
        _dishName = dishName,
        _id = id;

  factory Dish.emptyDish() {
    return Dish(
      dishName: '',
      imgPath: '',
      ingredients: [],
      price: 0,
    );
  }

  factory Dish.fromFirestore(String docId, Map<String, dynamic> doc) {
    return Dish(
      id: docId,
      dishName: doc['dishName'],
      imgPath: doc['imgPath'],
      ingredients: List<String>.from(doc['ingredients']),
      price: doc['price'].toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dishName': _dishName,
      'imgPath': _imgPath,
      'ingredients': _ingredients,
      'price': _price,
    };
  }

  String get dishName => _dishName;

  String get imgPath => _imgPath;

  List<String> get ingredients => _ingredients;

  double get price => _price;

  @override
  String toString() {
    return '$_dishName costs $_price';
  }
}
