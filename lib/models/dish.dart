class Dish {
  final String? _id;
  String _dishName, _imgPath;
  List<String> _ingredients;
  double _price;

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

  set setDishName(String value) {
    _dishName = value;
  }

  set setImgPath(value) {
    _imgPath = value;
  }

  set setIngredients(List<String> value) {
    _ingredients = value;
  }

  set setPrice(double value) {
    _price = value;
  }

  String? get getId => _id;

  String get getDishName => _dishName;

  String get getImgPath => _imgPath;

  List<String> get getIngredients => _ingredients;

  double get getPrice => _price;

  @override
  String toString() {
    return '$_dishName costs $_price';
  }
}
