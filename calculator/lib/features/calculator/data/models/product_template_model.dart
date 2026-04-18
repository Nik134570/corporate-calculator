class ProductTemplateModel {
  final String id;
  final String materialId;
  final String materialName;
  final String thickness;
  final double unitPrice;
  final bool allowTempered;
  final String discountType;
  final double discountValue;
  final String complexityType;
  final double complexityValue;
  final List<String> allowedProcessingIds;
  final List<String> allowedPieceWorkIds;

  ProductTemplateModel({
    required this.id,
    required this.materialId,
    required this.materialName,
    required this.thickness,
    required this.unitPrice,
    this.allowTempered = false,
    this.discountType = 'none',
    this.discountValue = 0,
    this.complexityType = 'none',
    this.complexityValue = 0,
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
      discountType: json['discountType'] ?? 'none',
      discountValue: double.parse((json['discountValue'] ?? 0).toString()),
      complexityType: json['complexityType'] ?? 'none',
      complexityValue: double.parse((json['complexityValue'] ?? 0).toString()),
      allowedProcessingIds: json['allowedProcessingIds'] != null
          ? List<String>.from(json['allowedProcessingIds'])
          : [],
      allowedPieceWorkIds: json['allowedPieceWorkIds'] != null
          ? List<String>.from(json['allowedPieceWorkIds'])
          : [],
    );
  }
}
