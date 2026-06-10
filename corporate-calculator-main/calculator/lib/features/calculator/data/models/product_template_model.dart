class ProductTemplateModel {
  final String id;
  final String materialId;
  final String materialName;
  final String thickness;
  final double unitPrice;
  final bool allowTempered;
  final String complexityType;
  final double complexityValue;
  final List<String> allowedProcessingIds;
  final List<String> allowedPieceWorkIds;
  final List<String> allowedDiscountIds;

  ProductTemplateModel({
    required this.id,
    required this.materialId,
    required this.materialName,
    required this.thickness,
    required this.unitPrice,
    this.allowTempered = false,
    this.complexityType = 'none',
    this.complexityValue = 0,
    List<String>? allowedProcessingIds,
    List<String>? allowedPieceWorkIds,
    List<String>? allowedDiscountIds,
  })  : allowedProcessingIds = allowedProcessingIds ?? [],
        allowedPieceWorkIds = allowedPieceWorkIds ?? [],
        allowedDiscountIds = allowedDiscountIds ?? [];

  String get displayName => '$materialName $thickness';

  factory ProductTemplateModel.fromJson(Map<String, dynamic> json) {
    return ProductTemplateModel(
      id: json['id'],
      materialId: json['materialId'],
      materialName: json['materialName'] ?? '',
      thickness: json['thickness'],
      unitPrice: double.parse(json['unitPrice'].toString()),
      allowTempered: json['allowTempered'] == true,
      complexityType: json['complexityType'] ?? 'none',
      complexityValue: double.parse((json['complexityValue'] ?? 0).toString()),
      allowedProcessingIds: json['allowedProcessingIds'] != null
          ? List<String>.from(json['allowedProcessingIds'])
          : [],
      allowedPieceWorkIds: json['allowedPieceWorkIds'] != null
          ? List<String>.from(json['allowedPieceWorkIds'])
          : [],
      allowedDiscountIds: json['allowedDiscountIds'] != null
          ? List<String>.from(json['allowedDiscountIds'])
          : [],
    );
  }
}
