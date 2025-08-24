class SosModel {
  final String id;
  final String userId;
  final List coords;
  final String message;
  final DateTime createdAt;

  SosModel({required this.id, required this.userId, required this.coords, required this.message, required this.createdAt});

  factory SosModel.fromJson(Map<String,dynamic> json) => SosModel(
      id: json['_id'] ?? '',
      userId: json['user'],
      coords: json['coords'] ?? [],
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String())
  );
}
