/// Public API for the on-device Legal Metrology (Packaged Commodities)
/// Rules, 2011 compliance audit.
///
/// Entry points:
///  * [runBarcodeAudit] — deterministic audit from a bar code / GTIN alone.
///  * [runLabelAudit]   — audit from an OCR-derived [PackageData] (+ optional bar code).
///
/// Everything is offline; [lookupProduct] only reaches the network when a
/// connection is available.
library legal_metrology;

export 'src/compliance/models.dart'
    show
        PackageData,
        RuleResult,
        ComplianceDiff,
        ComplianceScore,
        ComplianceReport,
        AnalysisSource,
        QuantityCategory,
        PackageType;
export 'src/compliance/gs1.dart' show classifyGtin, GtinInfo, validateGtin;
export 'src/compliance/audit.dart'
    show runBarcodeAudit, runLabelAudit, packageFromRecord;
export 'src/compliance/rulebook_engine.dart'
    show evaluate, scoreDiff, generateRecommendations, starRating;
export 'src/data/product_lookup.dart' show lookupProduct, LookupConfig, parseQuantity;
export 'src/data/product_record.dart' show ProductRecord;

// On-device extraction (Google ML Kit). Drop these + src/extraction/ if the
// host app already scans bar codes / does OCR.
export 'src/extraction/barcode_scanner.dart'
    show BarcodeScannerService, ScannedBarcode;
export 'src/extraction/label_ocr.dart' show LabelOcrService, OcrResult, OcrLine;
export 'src/extraction/text_parser.dart'
    show parseOcr, toPackageData, ParsedDeclarations;
