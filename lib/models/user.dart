class User {
  final String phone;
  final String password;

  User({required this.phone, required this.password});

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'password': password,
  };

  factory User.fromJson(Map<String, dynamic> json) =>
      User(phone: json['phone'], password: json['password']);
}
