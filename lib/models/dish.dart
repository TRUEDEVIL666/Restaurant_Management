class Dish {
  final String? _id;
  String _dishName, _imgPath, _category;
  List<String> _ingredients, _subCategories;
  double _price, _discount;

  Dish({
    String? id,
    required String dishName,
    required String imgPath,
    required List<String> ingredients,
    String? category,
    List<String>? subCategories,
    required double price,
    double? discount,
  })  : _id = id,
        _dishName = dishName,
        _imgPath = imgPath,
        _ingredients = ingredients,
        _category = category ?? '',
        _subCategories = subCategories ?? [],
        _price = price,
        _discount = discount ?? 0;

  factory Dish.emptyDish() {
    return Dish(
      dishName: '',
      imgPath: '',
      ingredients: [],
      category: '',
      subCategories: [],
      price: 0,
      discount: 0,
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
      discount: doc['discount'].toDouble(),
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
      'discount': _discount,
    };
  }

  String? get id => _id;

  @override
  String toString() {
    return '$_dishName costs $_price';
  }

  String get dishName => _dishName;

  set dishName(String value) {
    _dishName = value;
  }

  get imgPath => _imgPath;

  set imgPath(value) {
    _imgPath = value;
  }

  get category => _category;

  set category(value) {
    _category = value;
  }

  List<String> get ingredients => _ingredients;

  set ingredients(List<String> value) {
    _ingredients = value;
  }

  get subCategories => _subCategories;

  set subCategories(value) {
    _subCategories = value;
  }

  double get price => _price;

  set price(double value) {
    _price = value;
  }

  get discount => _discount;

  set discount(value) {
    _discount = value;
  }
}
