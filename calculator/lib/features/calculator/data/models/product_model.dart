class ProductModel {
  final String id;
  final String name;
  final String type; // AREA, LINEAR, PIECE
  final double unitPrice;
  final String unit;

  ProductModel({
    required this.id,
    required this.name,
    required this.type,
    required this.unitPrice,
    required this.unit,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      unitPrice: double.parse(json['unitPrice'].toString()),
      unit: json['unit'],
    );
  }
}
