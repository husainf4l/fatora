class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? role;
  final String? phone;
  final String? businessName;
  final String? businessAddress;
  final String? taxNumber;
  final String? logo;
  final bool isEmailVerified;
  final String? accessToken;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.role,
    this.phone,
    this.businessName,
    this.businessAddress,
    this.taxNumber,
    this.logo,
    this.isEmailVerified = false,
    this.accessToken,
  });

  // Full name convenience getter
  String get name => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      role: json['role'],
      phone: json['phone'],
      businessName: json['businessName'],
      businessAddress: json['businessAddress'],
      taxNumber: json['taxNumber'],
      logo: json['logo'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      accessToken: json['accessToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'phone': phone,
      'businessName': businessName,
      'businessAddress': businessAddress,
      'taxNumber': taxNumber,
      'logo': logo,
      'isEmailVerified': isEmailVerified,
      'accessToken': accessToken,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
    String? phone,
    String? businessName,
    String? businessAddress,
    String? taxNumber,
    String? logo,
    bool? isEmailVerified,
    String? accessToken,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      taxNumber: taxNumber ?? this.taxNumber,
      logo: logo ?? this.logo,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      accessToken: accessToken ?? this.accessToken,
    );
  }
}
