class MaterialModel {
  final String id;
  final String name;
  final bool isActive;

  MaterialModel({required this.id, required this.name, this.isActive = true});

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'],
      name: json['name'],
      isActive: json['isActive'] ?? true,
    );
  }
}
