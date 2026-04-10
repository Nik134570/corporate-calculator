class CalculationModel {
  final String id;
  final String title;
  final String clientName;
  final String? clientPhone;
  final String? clientAddress;
  final String? comment;
  final double totalPrice;
  final double delivery;
  final double lifting;
  final double consumables;
  final double measurement;
  final double installation;
  final String discountType;
  final double discountValue;
  final String complexityType;
  final double complexityValue;
  final String status; // DRAFT, PENDING, IN_REVIEW, APPROVED, REJECTED
  final bool hasPriceChanges;
  final DateTime createdAt;
  final String? createdByEmail;
  final String? createdByName;
  final List<CalcProductModel> products;
  final ReviewRequestModel? reviewRequest;

  CalculationModel({
    required this.id,
    required this.title,
    required this.clientName,
    this.clientPhone,
    this.clientAddress,
    this.comment,
    required this.totalPrice,
    this.delivery = 0,
    this.lifting = 0,
    this.consumables = 0,
    this.measurement = 0,
    this.installation = 0,
    this.discountType = 'none',
    this.discountValue = 0,
    this.complexityType = 'none',
    this.complexityValue = 0,
    this.status = 'DRAFT',
    this.hasPriceChanges = false,
    required this.createdAt,
    this.createdByEmail,
    this.createdByName,
    required this.products,
    this.reviewRequest,
  });

  double get productsTotal => products.fold(0, (s, p) => s + p.totalPrice * p.quantity);
  double get servicesTotal => delivery + lifting + consumables + measurement + installation;

  bool get isDraft =>
    status == 'DRAFT' &&
    (clientName.isEmpty || products.isEmpty);

  factory CalculationModel.fromJson(Map<String, dynamic> json) {
    return CalculationModel(
      id: json['id'],
      title: json['title'],
      clientName: json['clientName'],
      clientPhone: json['clientPhone'],
      clientAddress: json['clientAddress'],
      comment: json['comment'],
      totalPrice: double.parse(json['totalPrice'].toString()),
      delivery: double.parse((json['delivery'] ?? 0).toString()),
      lifting: double.parse((json['lifting'] ?? 0).toString()),
      consumables: double.parse((json['consumables'] ?? 0).toString()),
      measurement: double.parse((json['measurement'] ?? 0).toString()),
      installation: double.parse((json['installation'] ?? 0).toString()),
      discountType: json['discountType'] ?? 'none',
      discountValue: double.parse((json['discountValue'] ?? 0).toString()),
      complexityType: json['complexityType'] ?? 'none',
      complexityValue: double.parse((json['complexityValue'] ?? 0).toString()),
      status: json['status'] ?? 'DRAFT',
      hasPriceChanges: json['hasPriceChanges'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      createdByEmail: json['createdBy']?['email'],
      createdByName: json['createdBy']?['fullName'],
      products: (json['products'] as List? ?? [])
          .map((e) => CalcProductModel.fromJson(e))
          .toList(),
      reviewRequest: json['reviewRequest'] != null
          ? ReviewRequestModel.fromJson(json['reviewRequest'])
          : null,
    );
  }
}

class ReviewRequestModel {
  final String id;
  final String? comment;
  final String? adminComment;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? requestedByEmail;
  final String? requestedByName;
  final String? reviewedByEmail;
  final String? reviewedByName;

  ReviewRequestModel({
    required this.id,
    this.comment,
    this.adminComment,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.requestedByEmail,
    this.requestedByName,
    this.reviewedByEmail,
    this.reviewedByName,
  });

  factory ReviewRequestModel.fromJson(Map<String, dynamic> json) => ReviewRequestModel(
        id: json['id'],
        comment: json['comment'],
        adminComment: json['adminComment'],
        status: json['status'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt'] ?? json['createdAt']),
        requestedByEmail: json['requestedBy']?['email'],
        requestedByName: json['requestedBy']?['fullName'],
        reviewedByEmail: json['reviewedBy']?['email'],
        reviewedByName: json['reviewedBy']?['fullName'],
      );
}

class CalcProductModel {
  final String id;
  final String name;
  final double width;
  final double height;
  final int quantity;
  final bool isTempered;
  final double pricePerSqm;
  final double? originalPricePerSqm;
  final double area;
  final double totalPrice;
  final String? materialName;
  final String? productTemplateId;
  final List<CalcProcessingModel> processings;
  final List<CalcPieceWorkModel> pieceWorks;

  CalcProductModel({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    this.quantity = 1,
    this.isTempered = false,
    required this.pricePerSqm,
    this.originalPricePerSqm,
    required this.area,
    required this.totalPrice,
    this.materialName,
    this.productTemplateId,
    required this.processings,
    required this.pieceWorks,
  });

  bool get hasPriceChange =>
      originalPricePerSqm != null && originalPricePerSqm != pricePerSqm;
  double get perimeter => 2 * (width / 1000 + height / 1000);

  factory CalcProductModel.fromJson(Map<String, dynamic> json) {
    return CalcProductModel(
      id: json['id'],
      name: json['name'],
      width: double.parse(json['width'].toString()),
      height: double.parse(json['height'].toString()),
      quantity: json['quantity'] ?? 1,
      isTempered: json['isTempered'] ?? false,
      pricePerSqm: double.parse(json['pricePerSqm'].toString()),
      originalPricePerSqm: json['originalPricePerSqm'] != null
          ? double.parse(json['originalPricePerSqm'].toString())
          : null,
      area: double.parse(json['area'].toString()),
      totalPrice: double.parse(json['totalPrice'].toString()),
      materialName: json['productTemplate']?['material']?['name'],
      productTemplateId: json['productTemplateId'],
      processings: (json['processings'] as List? ?? [])
          .map((e) => CalcProcessingModel.fromJson(e))
          .toList(),
      pieceWorks: (json['pieceWorks'] as List? ?? [])
          .map((e) => CalcPieceWorkModel.fromJson(e))
          .toList(),
    );
  }
}

class CalcProcessingModel {
  final String name;
  final double pricePerMeter;
  final double? originalPricePerMeter;
  final double totalPrice;

  CalcProcessingModel({
    required this.name,
    required this.pricePerMeter,
    this.originalPricePerMeter,
    required this.totalPrice,
  });

  bool get hasPriceChange =>
      originalPricePerMeter != null && originalPricePerMeter != pricePerMeter;

  factory CalcProcessingModel.fromJson(Map<String, dynamic> json) => CalcProcessingModel(
        name: json['name'],
        pricePerMeter: double.parse(json['pricePerMeter'].toString()),
        originalPricePerMeter: json['originalPricePerMeter'] != null
            ? double.parse(json['originalPricePerMeter'].toString())
            : null,
        totalPrice: double.parse(json['totalPrice'].toString()),
      );
}

class CalcPieceWorkModel {
  final String name;
  final int quantity;
  final double unitPrice;
  final double? originalUnitPrice;
  final double totalPrice;

  CalcPieceWorkModel({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.originalUnitPrice,
    required this.totalPrice,
  });

  bool get hasPriceChange =>
      originalUnitPrice != null && originalUnitPrice != unitPrice;



  factory CalcPieceWorkModel.fromJson(Map<String, dynamic> json) => CalcPieceWorkModel(
        name: json['name'],
        quantity: json['quantity'],
        unitPrice: double.parse(json['unitPrice'].toString()),
        originalUnitPrice: json['originalUnitPrice'] != null
            ? double.parse(json['originalUnitPrice'].toString())
            : null,
        totalPrice: double.parse(json['totalPrice'].toString()),
      );
}