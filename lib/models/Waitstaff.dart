class Waitstaff {
  final String id, username, password;

  Waitstaff({
    required this.id,
    required this.username,
    required this.password
  });

  factory Waitstaff.fromFirestore(String docId, Map<String, dynamic> doc) {
    return Waitstaff(
      id: docId,
      username: doc['username'],
      password: doc['password'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'password': password
    };
  }

  @override
  String toString() {
    return 'username is $username \n password is $password';
  }
}