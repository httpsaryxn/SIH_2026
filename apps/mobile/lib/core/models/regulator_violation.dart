class RegulatorOverlayBox {
  final double topPercent;
  final double leftPercent;
  final double widthPercent;
  final double heightPercent;
  final String label;
  final bool isViolation;

  const RegulatorOverlayBox({
    required this.topPercent,
    required this.leftPercent,
    required this.widthPercent,
    required this.heightPercent,
    required this.label,
    this.isViolation = true,
  });

  Map<String, dynamic> toJson() => {
        'top_percent': topPercent,
        'left_percent': leftPercent,
        'width_percent': widthPercent,
        'height_percent': heightPercent,
        'label': label,
        'is_violation': isViolation,
      };

  factory RegulatorOverlayBox.fromJson(Map<String, dynamic> json) =>
      RegulatorOverlayBox(
        topPercent: (json['top_percent'] as num).toDouble(),
        leftPercent: (json['left_percent'] as num).toDouble(),
        widthPercent: (json['width_percent'] as num).toDouble(),
        heightPercent: (json['height_percent'] as num).toDouble(),
        label: json['label'] as String? ?? '',
        isViolation: json['is_violation'] as bool? ?? true,
      );
}

class RegulatorDeclaration {
  final String fieldName;
  final String extractedValue;
  final int confidencePercent;
  final String status; // 'Compliant', 'Warning', 'Violation', 'Unable to Verify'
  final String ruleCitation;
  final String ruleDescription;

  const RegulatorDeclaration({
    required this.fieldName,
    required this.extractedValue,
    required this.confidencePercent,
    required this.status,
    required this.ruleCitation,
    required this.ruleDescription,
  });

  bool get isViolation => status == 'Violation';
  bool get isCompliant => status == 'Compliant';
  bool get isWarning => status == 'Warning';

  Map<String, dynamic> toJson() => {
        'field_name': fieldName,
        'extracted_value': extractedValue,
        'confidence_percent': confidencePercent,
        'status': status,
        'rule_citation': ruleCitation,
        'rule_description': ruleDescription,
      };

  factory RegulatorDeclaration.fromJson(Map<String, dynamic> json) =>
      RegulatorDeclaration(
        fieldName: json['field_name'] as String? ?? '',
        extractedValue: json['extracted_value'] as String? ?? '',
        confidencePercent: json['confidence_percent'] as int? ?? 0,
        status: json['status'] as String? ?? 'Unable to Verify',
        ruleCitation: json['rule_citation'] as String? ?? '',
        ruleDescription: json['rule_description'] as String? ?? '',
      );
}

class RegulatorViolation {
  final String id;
  final String scanId;
  final String productName;
  final String companyName;
  final String category;
  final String region;
  final String storeLocation;
  final String imageUrl;
  final String? frontLabelUrl;
  final String? curvedSurfaceUrl;
  final String? scaleReferenceUrl;
  final String severity; // 'High', 'Medium', 'Low'
  final String riskLevel; // 'High Risk', 'Medium Risk', 'Low Risk'
  final int confidenceScore;
  final String violationType;
  final String violationSummary;
  final DateTime capturedAt;
  final String status; // 'pending', 'confirmed', 'false_positive', 'escalated', 'manual_review'
  final List<RegulatorDeclaration> declarations;
  final List<RegulatorOverlayBox> overlayBoxes;

  /// Returns all non-empty image URLs with their role labels.
  List<MapEntry<String, String>> get allLabeledImages {
    final images = <MapEntry<String, String>>[];
    if (frontLabelUrl != null && frontLabelUrl!.isNotEmpty) {
      images.add(MapEntry('Front Label', frontLabelUrl!));
    }
    if (curvedSurfaceUrl != null && curvedSurfaceUrl!.isNotEmpty) {
      images.add(MapEntry('Curved Surface', curvedSurfaceUrl!));
    }
    if (scaleReferenceUrl != null && scaleReferenceUrl!.isNotEmpty) {
      images.add(MapEntry('Scale Reference', scaleReferenceUrl!));
    }
    // Fallback: if no role-specific URLs, use the primary imageUrl
    if (images.isEmpty && imageUrl.isNotEmpty) {
      images.add(MapEntry('Evidence', imageUrl));
    }
    return images;
  }

  const RegulatorViolation({
    required this.id,
    required this.scanId,
    required this.productName,
    required this.companyName,
    required this.category,
    required this.region,
    required this.storeLocation,
    required this.imageUrl,
    this.frontLabelUrl,
    this.curvedSurfaceUrl,
    this.scaleReferenceUrl,
    required this.severity,
    required this.riskLevel,
    required this.confidenceScore,
    required this.violationType,
    required this.violationSummary,
    required this.capturedAt,
    this.status = 'pending',
    this.declarations = const [],
    this.overlayBoxes = const [],
  });

  RegulatorViolation copyWith({
    String? id,
    String? scanId,
    String? productName,
    String? companyName,
    String? category,
    String? region,
    String? storeLocation,
    String? imageUrl,
    String? frontLabelUrl,
    String? curvedSurfaceUrl,
    String? scaleReferenceUrl,
    String? severity,
    String? riskLevel,
    int? confidenceScore,
    String? violationType,
    String? violationSummary,
    DateTime? capturedAt,
    String? status,
    List<RegulatorDeclaration>? declarations,
    List<RegulatorOverlayBox>? overlayBoxes,
  }) {
    return RegulatorViolation(
      id: id ?? this.id,
      scanId: scanId ?? this.scanId,
      productName: productName ?? this.productName,
      companyName: companyName ?? this.companyName,
      category: category ?? this.category,
      region: region ?? this.region,
      storeLocation: storeLocation ?? this.storeLocation,
      imageUrl: imageUrl ?? this.imageUrl,
      frontLabelUrl: frontLabelUrl ?? this.frontLabelUrl,
      curvedSurfaceUrl: curvedSurfaceUrl ?? this.curvedSurfaceUrl,
      scaleReferenceUrl: scaleReferenceUrl ?? this.scaleReferenceUrl,
      severity: severity ?? this.severity,
      riskLevel: riskLevel ?? this.riskLevel,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      violationType: violationType ?? this.violationType,
      violationSummary: violationSummary ?? this.violationSummary,
      capturedAt: capturedAt ?? this.capturedAt,
      status: status ?? this.status,
      declarations: declarations ?? this.declarations,
      overlayBoxes: overlayBoxes ?? this.overlayBoxes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scan_id': scanId,
        'product_name': productName,
        'company_name': companyName,
        'category': category,
        'region': region,
        'store_location': storeLocation,
        'image_url': imageUrl,
        'front_label_url': frontLabelUrl,
        'curved_surface_url': curvedSurfaceUrl,
        'scale_reference_url': scaleReferenceUrl,
        'severity': severity,
        'risk_level': riskLevel,
        'confidence_score': confidenceScore,
        'violation_type': violationType,
        'violation_summary': violationSummary,
        'captured_at': capturedAt.toIso8601String(),
        'status': status,
        'declarations': declarations.map((d) => d.toJson()).toList(),
        'overlay_boxes': overlayBoxes.map((o) => o.toJson()).toList(),
      };

  factory RegulatorViolation.fromJson(Map<String, dynamic> json) =>
      RegulatorViolation(
        id: json['id'] as String? ?? '',
        scanId: json['scan_id'] as String? ?? '',
        productName: json['product_name'] as String? ?? '',
        companyName: json['company_name'] as String? ?? '',
        category: json['category'] as String? ?? '',
        region: json['region'] as String? ?? '',
        storeLocation: json['store_location'] as String? ?? '',
        imageUrl: json['image_url'] as String? ?? '',
        frontLabelUrl: json['front_label_url'] as String?,
        curvedSurfaceUrl: json['curved_surface_url'] as String?,
        scaleReferenceUrl: json['scale_reference_url'] as String?,
        severity: json['severity'] as String? ?? 'Medium',
        riskLevel: json['risk_level'] as String? ?? 'Medium Risk',
        confidenceScore: json['confidence_score'] as int? ?? 85,
        violationType: json['violation_type'] as String? ?? 'General',
        violationSummary: json['violation_summary'] as String? ?? '',
        capturedAt: json['captured_at'] != null
            ? DateTime.parse(json['captured_at'] as String)
            : DateTime.now(),
        status: json['status'] as String? ?? 'pending',
        declarations: (json['declarations'] as List<dynamic>?)
                ?.map((d) =>
                    RegulatorDeclaration.fromJson(d as Map<String, dynamic>))
                .toList() ??
            const [],
        overlayBoxes: (json['overlay_boxes'] as List<dynamic>?)
                ?.map((o) =>
                    RegulatorOverlayBox.fromJson(o as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
