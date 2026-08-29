class SmallBusinessIngredientModel {
  final String? id;
  final String name;
  final double? percentage;
  final int orderIndex;

  const SmallBusinessIngredientModel({
    this.id,
    required this.name,
    this.percentage,
    this.orderIndex = 0,
  });

  Map<String, dynamic> toMap(String labelId) {
    final map = <String, dynamic>{
      'label_id': labelId,
      'name': name,
      'percentage': percentage,
      'order_index': orderIndex,
    };
    if (id != null && id!.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  factory SmallBusinessIngredientModel.fromMap(Map<String, dynamic> map) {
    return SmallBusinessIngredientModel(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? '',
      percentage: map['percentage'] != null
          ? double.tryParse(map['percentage'].toString())
          : null,
      orderIndex: map['order_index'] is int ? map['order_index'] as int : 0,
    );
  }

  SmallBusinessIngredientModel copyWith({
    String? id,
    String? name,
    double? percentage,
    int? orderIndex,
  }) {
    return SmallBusinessIngredientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      percentage: percentage ?? this.percentage,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}

class SmallBusinessNutrientModel {
  final String? id;
  final String label;
  final String value;
  final String unit;
  final bool isRequired;
  final bool isSubNutrient;
  final int orderIndex;

  const SmallBusinessNutrientModel({
    this.id,
    required this.label,
    required this.value,
    this.unit = 'g',
    this.isRequired = false,
    this.isSubNutrient = false,
    this.orderIndex = 0,
  });

  Map<String, dynamic> toMap(String labelId) {
    final map = <String, dynamic>{
      'label_id': labelId,
      'label': label,
      'value': value,
      'unit': unit,
      'is_required': isRequired,
      'is_sub_nutrient': isSubNutrient,
      'order_index': orderIndex,
    };
    if (id != null && id!.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  factory SmallBusinessNutrientModel.fromMap(Map<String, dynamic> map) {
    return SmallBusinessNutrientModel(
      id: map['id']?.toString(),
      label: map['label']?.toString() ?? '',
      value: map['value']?.toString() ?? '0',
      unit: map['unit']?.toString() ?? 'g',
      isRequired: map['is_required'] == true,
      isSubNutrient: map['is_sub_nutrient'] == true,
      orderIndex: map['order_index'] is int ? map['order_index'] as int : 0,
    );
  }

  SmallBusinessNutrientModel copyWith({
    String? id,
    String? label,
    String? value,
    String? unit,
    bool? isRequired,
    bool? isSubNutrient,
    int? orderIndex,
  }) {
    return SmallBusinessNutrientModel(
      id: id ?? this.id,
      label: label ?? this.label,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      isRequired: isRequired ?? this.isRequired,
      isSubNutrient: isSubNutrient ?? this.isSubNutrient,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}

class SmallBusinessClaimModel {
  final String? id;
  final String? claimId;
  final String title;
  final String description;
  final String category;
  final bool requiresLabReport;
  final String? legalReference;

  const SmallBusinessClaimModel({
    this.id,
    this.claimId,
    required this.title,
    this.description = '',
    this.category = 'common',
    this.requiresLabReport = false,
    this.legalReference,
  });

  Map<String, dynamic> toMap(String labelId) {
    final map = <String, dynamic>{
      'label_id': labelId,
      'claim_id': claimId,
      'title': title,
      'description': description,
      'category': category,
      'requires_lab_report': requiresLabReport,
      'legal_reference': legalReference,
    };
    if (id != null && id!.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  factory SmallBusinessClaimModel.fromMap(Map<String, dynamic> map) {
    return SmallBusinessClaimModel(
      id: map['id']?.toString(),
      claimId: map['claim_id']?.toString(),
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? 'common',
      requiresLabReport: map['requires_lab_report'] == true,
      legalReference: map['legal_reference']?.toString(),
    );
  }

  SmallBusinessClaimModel copyWith({
    String? id,
    String? claimId,
    String? title,
    String? description,
    String? category,
    bool? requiresLabReport,
    String? legalReference,
  }) {
    return SmallBusinessClaimModel(
      id: id ?? this.id,
      claimId: claimId ?? this.claimId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      requiresLabReport: requiresLabReport ?? this.requiresLabReport,
      legalReference: legalReference ?? this.legalReference,
    );
  }
}

class SmallBusinessLabelModel {
  final String? id;
  final String? userId;
  final String brandName;
  final String productName;
  final String productCategory;
  final String typeFlavour;
  final String? logoUrl;
  final String status; // 'draft', 'ready', 'needs_review'
  final int completionPercentage;
  final int currentStep;
  final String ingredientSource;
  final String netQuantity;
  final String netQuantityUnit;
  final String servingSize;
  final String servingSizeUnit;
  final String displayMode;
  final String labelFormat;
  final String targetAudience;
  final String ageGroup;
  final String manufacturerName;
  final String manufacturerAddress;
  final bool packerAddressSameAsManufacturer;
  final String? packerName;
  final String? packerAddress;
  final String fssaiLicenseNumber;
  final String? marketedBy;
  final String countryOfOrigin;
  final String consumerCarePhone;
  final String consumerCareEmail;
  final String? consumerCareWebsite;
  final String mrp;
  final String usp;
  final String batchNumber;
  final String mfgDate;
  final String bestBefore;
  final String storageInstructions;
  final String? usageInstructions;
  final String packagingType;
  final bool isVegetarian;
  final String recyclingMark;
  final int complianceScore;
  final String complianceStatus;
  final String exportFormat;
  final String labelDimension;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<SmallBusinessIngredientModel> ingredients;
  final List<String> allergens;
  final List<SmallBusinessNutrientModel> nutrients;
  final List<SmallBusinessClaimModel> claims;

  const SmallBusinessLabelModel({
    this.id,
    this.userId,
    this.brandName = '',
    this.productName = '',
    this.productCategory = '',
    this.typeFlavour = '',
    this.logoUrl,
    this.status = 'draft',
    this.completionPercentage = 0,
    this.currentStep = 1,
    this.ingredientSource = 'noLabReport',
    this.netQuantity = '',
    this.netQuantityUnit = 'g',
    this.servingSize = '',
    this.servingSizeUnit = 'g',
    this.displayMode = 'perServing',
    this.labelFormat = 'table',
    this.targetAudience = 'All Age Groups (General)',
    this.ageGroup = 'All Age Groups (General)',
    this.manufacturerName = '',
    this.manufacturerAddress = '',
    this.packerAddressSameAsManufacturer = true,
    this.packerName,
    this.packerAddress,
    this.fssaiLicenseNumber = '',
    this.marketedBy,
    this.countryOfOrigin = 'India',
    this.consumerCarePhone = '',
    this.consumerCareEmail = '',
    this.consumerCareWebsite = '',
    this.mrp = '',
    this.usp = '',
    this.batchNumber = '',
    this.mfgDate = '',
    this.bestBefore = '12 Months from Packaging',
    this.storageInstructions = '',
    this.usageInstructions,
    this.packagingType = 'Food Grade Glass Jar',
    this.isVegetarian = true,
    this.recyclingMark = 'Keep Clean (MoEFCC Disposal Logo)',
    this.complianceScore = 0,
    this.complianceStatus = 'Draft in Progress',
    this.exportFormat = 'pdf',
    this.labelDimension = 'Standard Pouch (100 × 150 mm)',
    this.createdAt,
    this.updatedAt,
    this.ingredients = const [],
    this.allergens = const [],
    this.nutrients = const [],
    this.claims = const [],
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'brand_name': brandName,
      'product_name': productName,
      'product_category': productCategory,
      'type_flavour': typeFlavour,
      'logo_url': logoUrl,
      'status': status,
      'completion_percentage': completionPercentage,
      'current_step': currentStep,
      'ingredient_source': ingredientSource,
      'net_quantity': netQuantity,
      'net_quantity_unit': netQuantityUnit,
      'serving_size': servingSize,
      'serving_size_unit': servingSizeUnit,
      'display_mode': displayMode,
      'label_format': labelFormat,
      'target_audience': targetAudience,
      'age_group': ageGroup,
      'manufacturer_name': manufacturerName,
      'manufacturer_address': manufacturerAddress,
      'packer_address_same_as_manufacturer': packerAddressSameAsManufacturer,
      'packer_name': packerName,
      'packer_address': packerAddress,
      'fssai_license_number': fssaiLicenseNumber,
      'marketed_by': marketedBy,
      'country_of_origin': countryOfOrigin,
      'consumer_care_phone': consumerCarePhone,
      'consumer_care_email': consumerCareEmail,
      'consumer_care_website': consumerCareWebsite,
      'mrp': mrp,
      'usp': usp,
      'batch_number': batchNumber,
      'mfg_date': mfgDate,
      'best_before': bestBefore,
      'storage_instructions': storageInstructions,
      'usage_instructions': usageInstructions,
      'packaging_type': packagingType,
      'is_vegetarian': isVegetarian,
      'recycling_mark': recyclingMark,
      'compliance_score': complianceScore,
      'compliance_status': complianceStatus,
      'export_format': exportFormat,
      'label_dimension': labelDimension,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (id != null && id!.isNotEmpty) {
      map['id'] = id;
    }
    if (userId != null && userId!.isNotEmpty) {
      map['user_id'] = userId;
    }

    return map;
  }

  factory SmallBusinessLabelModel.fromMap(Map<String, dynamic> map) {
    return SmallBusinessLabelModel(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString(),
      brandName: map['brand_name']?.toString() ?? '',
      productName: map['product_name']?.toString() ?? '',
      productCategory: map['product_category']?.toString() ?? 'General Food',
      typeFlavour: map['type_flavour']?.toString() ?? '',
      logoUrl: map['logo_url']?.toString(),
      status: map['status']?.toString() ?? 'draft',
      completionPercentage:
          map['completion_percentage'] is int
              ? map['completion_percentage'] as int
              : int.tryParse(map['completion_percentage']?.toString() ?? '') ??
                  17,
      currentStep:
          map['current_step'] is int
              ? map['current_step'] as int
              : int.tryParse(map['current_step']?.toString() ?? '') ?? 1,
      ingredientSource: map['ingredient_source']?.toString() ?? 'noLabReport',
      netQuantity: map['net_quantity']?.toString() ?? '100',
      netQuantityUnit: map['net_quantity_unit']?.toString() ?? 'g',
      servingSize: map['serving_size']?.toString() ?? '30',
      servingSizeUnit: map['serving_size_unit']?.toString() ?? 'g',
      displayMode: map['display_mode']?.toString() ?? 'perServing',
      labelFormat: map['label_format']?.toString() ?? 'table',
      targetAudience: map['target_audience']?.toString() ?? 'General',
      ageGroup: map['age_group']?.toString() ?? 'Adults (18+)',
      manufacturerName: map['manufacturer_name']?.toString() ?? '',
      manufacturerAddress: map['manufacturer_address']?.toString() ?? '',
      packerAddressSameAsManufacturer:
          map['packer_address_same_as_manufacturer'] != false,
      packerName: map['packer_name']?.toString(),
      packerAddress: map['packer_address']?.toString(),
      fssaiLicenseNumber: map['fssai_license_number']?.toString() ?? '',
      marketedBy: map['marketed_by']?.toString(),
      countryOfOrigin: map['country_of_origin']?.toString() ?? 'India',
      consumerCarePhone: map['consumer_care_phone']?.toString() ?? '',
      consumerCareEmail: map['consumer_care_email']?.toString() ?? '',
      consumerCareWebsite: map['consumer_care_website']?.toString(),
      mrp: map['mrp']?.toString() ?? '0.00',
      usp: map['usp']?.toString() ?? '',
      batchNumber: map['batch_number']?.toString() ?? '',
      mfgDate: map['mfg_date']?.toString() ?? '',
      bestBefore:
          map['best_before']?.toString() ?? '12 Months from Packaging',
      storageInstructions: map['storage_instructions']?.toString() ?? '',
      usageInstructions: map['usage_instructions']?.toString(),
      packagingType:
          map['packaging_type']?.toString() ?? 'Food Grade Glass Jar',
      isVegetarian: map['is_vegetarian'] != false,
      recyclingMark:
          map['recycling_mark']?.toString() ??
          'Keep Clean (MoEFCC Disposal Logo)',
      complianceScore:
          map['compliance_score'] is int
              ? map['compliance_score'] as int
              : int.tryParse(map['compliance_score']?.toString() ?? '') ?? 98,
      complianceStatus:
          map['compliance_status']?.toString() ?? 'Verified Compliant',
      exportFormat: map['export_format']?.toString() ?? 'pdf',
      labelDimension:
          map['label_dimension']?.toString() ??
          'Standard Pouch (100 × 150 mm)',
      createdAt:
          map['created_at'] != null
              ? DateTime.tryParse(map['created_at'].toString())
              : null,
      updatedAt:
          map['updated_at'] != null
              ? DateTime.tryParse(map['updated_at'].toString())
              : null,
      ingredients:
          map['ingredients'] is List
              ? (map['ingredients'] as List)
                  .map(
                    (i) => SmallBusinessIngredientModel.fromMap(
                      Map<String, dynamic>.from(i as Map),
                    ),
                  )
                  .toList()
              : const [],
      allergens:
          map['allergens'] is List
              ? (map['allergens'] as List).map((a) {
                if (a is Map && a.containsKey('allergen_name')) {
                  return a['allergen_name'].toString();
                }
                return a.toString();
              }).toList()
              : const [],
      nutrients:
          map['nutrients'] is List
              ? (map['nutrients'] as List)
                  .map(
                    (n) => SmallBusinessNutrientModel.fromMap(
                      Map<String, dynamic>.from(n as Map),
                    ),
                  )
                  .toList()
              : const [],
      claims:
          map['claims'] is List
              ? (map['claims'] as List)
                  .map(
                    (c) => SmallBusinessClaimModel.fromMap(
                      Map<String, dynamic>.from(c as Map),
                    ),
                  )
                  .toList()
              : const [],
    );
  }

  SmallBusinessLabelModel copyWith({
    String? id,
    String? userId,
    String? brandName,
    String? productName,
    String? productCategory,
    String? typeFlavour,
    String? logoUrl,
    String? status,
    int? completionPercentage,
    int? currentStep,
    String? ingredientSource,
    String? netQuantity,
    String? netQuantityUnit,
    String? servingSize,
    String? servingSizeUnit,
    String? displayMode,
    String? labelFormat,
    String? targetAudience,
    String? ageGroup,
    String? manufacturerName,
    String? manufacturerAddress,
    bool? packerAddressSameAsManufacturer,
    String? packerName,
    String? packerAddress,
    String? fssaiLicenseNumber,
    String? marketedBy,
    String? countryOfOrigin,
    String? consumerCarePhone,
    String? consumerCareEmail,
    String? consumerCareWebsite,
    String? mrp,
    String? usp,
    String? batchNumber,
    String? mfgDate,
    String? bestBefore,
    String? storageInstructions,
    String? usageInstructions,
    String? packagingType,
    bool? isVegetarian,
    String? recyclingMark,
    int? complianceScore,
    String? complianceStatus,
    String? exportFormat,
    String? labelDimension,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SmallBusinessIngredientModel>? ingredients,
    List<String>? allergens,
    List<SmallBusinessNutrientModel>? nutrients,
    List<SmallBusinessClaimModel>? claims,
  }) {
    return SmallBusinessLabelModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      brandName: brandName ?? this.brandName,
      productName: productName ?? this.productName,
      productCategory: productCategory ?? this.productCategory,
      typeFlavour: typeFlavour ?? this.typeFlavour,
      logoUrl: logoUrl ?? this.logoUrl,
      status: status ?? this.status,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      currentStep: currentStep ?? this.currentStep,
      ingredientSource: ingredientSource ?? this.ingredientSource,
      netQuantity: netQuantity ?? this.netQuantity,
      netQuantityUnit: netQuantityUnit ?? this.netQuantityUnit,
      servingSize: servingSize ?? this.servingSize,
      servingSizeUnit: servingSizeUnit ?? this.servingSizeUnit,
      displayMode: displayMode ?? this.displayMode,
      labelFormat: labelFormat ?? this.labelFormat,
      targetAudience: targetAudience ?? this.targetAudience,
      ageGroup: ageGroup ?? this.ageGroup,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      manufacturerAddress: manufacturerAddress ?? this.manufacturerAddress,
      packerAddressSameAsManufacturer:
          packerAddressSameAsManufacturer ??
          this.packerAddressSameAsManufacturer,
      packerName: packerName ?? this.packerName,
      packerAddress: packerAddress ?? this.packerAddress,
      fssaiLicenseNumber: fssaiLicenseNumber ?? this.fssaiLicenseNumber,
      marketedBy: marketedBy ?? this.marketedBy,
      countryOfOrigin: countryOfOrigin ?? this.countryOfOrigin,
      consumerCarePhone: consumerCarePhone ?? this.consumerCarePhone,
      consumerCareEmail: consumerCareEmail ?? this.consumerCareEmail,
      consumerCareWebsite: consumerCareWebsite ?? this.consumerCareWebsite,
      mrp: mrp ?? this.mrp,
      usp: usp ?? this.usp,
      batchNumber: batchNumber ?? this.batchNumber,
      mfgDate: mfgDate ?? this.mfgDate,
      bestBefore: bestBefore ?? this.bestBefore,
      storageInstructions: storageInstructions ?? this.storageInstructions,
      usageInstructions: usageInstructions ?? this.usageInstructions,
      packagingType: packagingType ?? this.packagingType,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      recyclingMark: recyclingMark ?? this.recyclingMark,
      complianceScore: complianceScore ?? this.complianceScore,
      complianceStatus: complianceStatus ?? this.complianceStatus,
      exportFormat: exportFormat ?? this.exportFormat,
      labelDimension: labelDimension ?? this.labelDimension,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ingredients: ingredients ?? this.ingredients,
      allergens: allergens ?? this.allergens,
      nutrients: nutrients ?? this.nutrients,
      claims: claims ?? this.claims,
    );
  }
}
