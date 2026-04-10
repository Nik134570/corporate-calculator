class ProductTemplateModel {
  final String id;
  final String materialId;
  final String materialName;
  final String thickness;
  final double unitPrice;
  final bool allowTempered;
  final List<String> allowedProcessingIds;
  final List<String> allowedPieceWorkIds;

  ProductTemplateModel({
    required this.id,
    required this.materialId,
    required this.materialName,
    required this.thickness,
    required this.unitPrice,
    this.allowTempered = false,
    List<String>? allowedProcessingIds,
    List<String>? allowedPieceWorkIds,
  })  : allowedProcessingIds = allowedProcessingIds ?? [],
        allowedPieceWorkIds = allowedPieceWorkIds ?? [];

  String get displayName => '$materialName $thickness';

  factory ProductTemplateModel.fromJson(Map<String, dynamic> json) {
    return ProductTemplateModel(
      id: json['id'],
      materialId: json['materialId'],
      materialName: json['materialName'] ?? '',
      thickness: json['thickness'],
      unitPrice: double.parse(json['unitPrice'].toString()),
      allowTempered: json['allowTempered'] == true,
      allowedProcessingIds: json['allowedProcessingIds'] != null
          ? List<String>.from(json['allowedProcessingIds'])
          : [],
      allowedPieceWorkIds: json['allowedPieceWorkIds'] != null
          ? List<String>.from(json['allowedPieceWorkIds'])
          : [],
    );
  }
}
