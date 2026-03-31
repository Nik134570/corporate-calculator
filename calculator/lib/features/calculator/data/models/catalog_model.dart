class ServiceTemplateModel {
  final String id;
  final String name;
  final double defaultPrice;

  ServiceTemplateModel({required this.id, required this.name, required this.defaultPrice});

  factory ServiceTemplateModel.fromJson(Map<String, dynamic> json) => ServiceTemplateModel(
        id: json['id'],
        name: json['name'],
        defaultPrice: double.parse(json['defaultPrice'].toString()),
      );
}

class ProcessingTemplateModel {
  final String id;
  final String name;
  final double pricePerMeter;

  ProcessingTemplateModel({required this.id, required this.name, required this.pricePerMeter});

  factory ProcessingTemplateModel.fromJson(Map<String, dynamic> json) => ProcessingTemplateModel(
        id: json['id'],
        name: json['name'],
        pricePerMeter: double.parse(json['pricePerMeter'].toString()),
      );
}

class PieceWorkTemplateModel {
  final String id;
  final String name;
  final double unitPrice;

  PieceWorkTemplateModel({required this.id, required this.name, required this.unitPrice});

  factory PieceWorkTemplateModel.fromJson(Map<String, dynamic> json) => PieceWorkTemplateModel(
        id: json['id'],
        name: json['name'],
        unitPrice: double.parse(json['unitPrice'].toString()),
      );
}

class AppSettingsModel {
  final String id;
  final double temperedPrice;

  AppSettingsModel({required this.id, required this.temperedPrice});

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) => AppSettingsModel(
        id: json['id'],
        temperedPrice: double.parse(json['temperedPrice'].toString()),
      );
}