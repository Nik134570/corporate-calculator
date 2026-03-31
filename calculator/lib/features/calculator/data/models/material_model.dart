class MaterialModel {
  final String id;
  final String name;
  final double unitPrice;

  MaterialModel({required this.id, required this.name, required this.unitPrice});

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'],
      name: json['name'],
      unitPrice: double.parse(json['unitPrice'].toString()),
    );
  }
}