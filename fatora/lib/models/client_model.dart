class Client {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? taxNumber;
  final String? notes;
  final DateTime createdAt;
  final bool isActive;

  Client({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.taxNumber,
    this.notes,
    required this.createdAt,
    this.isActive = true,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      taxNumber: json['taxNumber'],
      notes: json['notes'],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'taxNumber': taxNumber,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  Client copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? taxNumber,
    String? notes,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      taxNumber: taxNumber ?? this.taxNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
