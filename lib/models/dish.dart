class Dish {
  final String? _id;
  String _dishName, _imgPath, _category;
  List<String> _ingredients, _subCategories;
  double _price;

  Dish({
    String? id,
    required String dishName,
    required String imgPath,
    required List<String> ingredients,
    required String category,
    required List<String> subCategories,
    required double price,
  })  : _id = id,
        _dishName = dishName,
        _imgPath = imgPath,
        _ingredients = ingredients,
        _category = category,
        _subCategories = subCategories,
        _price = price;

  factory Dish.emptyDish() {
    return Dish(
      dishName: '',
      imgPath: '',
      ingredients: [],
      category: '',
      subCategories: [],
      price: 0,
    );
  }

  factory Dish.fromFirestore(String docId, Map<String, dynamic> doc) {
    return Dish(
      id: docId,
      dishName: doc['dishName'],
      imgPath: doc['imgPath'],
      ingredients: List<String>.from(doc['ingredients']),
      category: doc['category'],
      subCategories: List<String>.from(doc['subCategories']),
      price: doc['price'].toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dishName': _dishName,
      'imgPath': _imgPath,
      'ingredients': _ingredients,
      'category': _category,
      'subCategories': _subCategories,
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

  set setCategory(String value) {
    _category = value;
  }

  set setSubCategories(List<String> value) {
    _subCategories = value;
  }

  set setPrice(double value) {
    _price = value;
  }

  String? get getId => _id;

  String get getDishName => _dishName;

  String get getImgPath => _imgPath;

  List<String> get getIngredients => _ingredients;

  String get getCategory => _category;

  List<String> get getSubCategories => _subCategories;

  double get getPrice => _price;

  @override
  String toString() {
    return '$_dishName costs $_price';
  }
}
