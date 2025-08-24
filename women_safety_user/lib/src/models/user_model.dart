class UserModel {
  final String id;
  final String name;
  final String phone;
  final String role;
  final List<String> parents;
  final List<String> children;
  final Map<String, dynamic>? lastLocation;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.parents,
    required this.children,
    this.lastLocation
  });

  factory UserModel.fromJson(Map<String,dynamic> json) => UserModel(
    id: json['_id'] ?? json['id'] ?? '',
    name: json['name'] ?? '',
    phone: json['phone'] ?? '',
    role: json['role'] ?? 'user',
    parents: List<String>.from(json['parents'] ?? []),
    children: List<String>.from(json['children'] ?? []),
    lastLocation: json['lastLocation'],
  );
}
