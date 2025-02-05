class User {
  final String? _id;
  String _username, _password, _phoneNumber;

  User({
    String? id,
    required String username,
    required String password,
    required String phoneNumber,
  })  : _id = id,
        _username = username,
        _password = password,
        _phoneNumber = phoneNumber;

  factory User.fromFirestore(String docId, Map<String, dynamic> doc) {
    return User(
      id: docId,
      username: doc['username'],
      password: doc['password'],
      phoneNumber: doc['phoneNumber'],
    );
  }
}
