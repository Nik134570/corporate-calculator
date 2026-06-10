class ServiceModel {
  final String id;
  final String name;
  final String type;
  final double defaultPrice;

  ServiceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.defaultPrice,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      defaultPrice: double.parse(json['defaultPrice'].toString()),
    );
  }
}
