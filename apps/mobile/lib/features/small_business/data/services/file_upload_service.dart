import 'dart:async';
import 'package:flutter/foundation.dart';

// Conditional import for web HTML vs non-web
import 'file_upload_service_stub.dart'
    if (dart.library.html) 'file_upload_service_web.dart' as platform_picker;

class UploadedFilePayload {
  final String name;
  final int sizeInBytes;
  final String? dataUrl;
  final String extension;

  const UploadedFilePayload({
    required this.name,
    required this.sizeInBytes,
    this.dataUrl,
    required this.extension,
  });

  String get formattedSize {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class DetectedLabReportData {
  final String fileName;
  final String laboratoryName;
  final String reportDate;
  final String sampleDescription;
  final List<DetectedIngredient> ingredients;
  final List<String> allergens;
  final Map<String, String> nutrients;

  const DetectedLabReportData({
    required this.fileName,
    required this.laboratoryName,
    required this.reportDate,
    required this.sampleDescription,
    required this.ingredients,
    required this.allergens,
    required this.nutrients,
  });
}

class DetectedIngredient {
  final String name;
  final double percentage;

  const DetectedIngredient({required this.name, required this.percentage});
}

class FileUploadService {
  /// Opens the system file manager to pick an image (PNG, JPG, JPEG, WEBP, SVG)
  static Future<UploadedFilePayload?> pickImage() async {
    try {
      return await platform_picker.pickFile(
        acceptedTypes: 'image/png,image/jpeg,image/jpg,image/webp,image/svg+xml',
      );
    } catch (e) {
      debugPrint('Error opening system file picker for image: $e');
      return null;
    }
  }

  /// Opens the system file manager to pick a document (PDF, PNG, JPG, JPEG, DOCX)
  static Future<UploadedFilePayload?> pickLabReportDocument() async {
    try {
      return await platform_picker.pickFile(
        acceptedTypes: 'application/pdf,image/png,image/jpeg,image/jpg,.pdf,.png,.jpg,.jpeg',
      );
    } catch (e) {
      debugPrint('Error opening system file picker for document: $e');
      return null;
    }
  }

  /// AI / OCR Simulation parser for Certificate of Analysis (CoA) & Accredited Lab Reports
  static Future<DetectedLabReportData> parseLabReport(UploadedFilePayload file) async {
    // Simulate brief OCR analysis delay
    await Future.delayed(const Duration(milliseconds: 900));

    final nameLower = file.name.toLowerCase();

    if (nameLower.contains('honey') || nameLower.contains('sweet')) {
      return DetectedLabReportData(
        fileName: file.name,
        laboratoryName: 'NABL Accredited Testing Laboratory (ISO 17025)',
        reportDate: 'Aug 2026',
        sampleDescription: 'Raw Forest Honey CoA',
        ingredients: const [
          DetectedIngredient(name: 'Raw Wild Forest Honey', percentage: 99.5),
          DetectedIngredient(name: 'Natural Pollen Extracts', percentage: 0.5),
        ],
        allergens: const ['Pollen Allergens (trace)'],
        nutrients: const {
          'Calories': '304',
          'Total Fat': '0',
          'Saturated Fat': '0',
          'Sodium': '4',
          'Carbohydrates': '82.4',
          'Dietary Fiber': '0.2',
          'Total Sugars': '82.1',
          'Added Sugars': '0',
          'Protein': '0.3',
          'Potassium (K)': '52',
          'Iron (Fe)': '0.42',
        },
      );
    } else if (nameLower.contains('oil') || nameLower.contains('ghee')) {
      return DetectedLabReportData(
        fileName: file.name,
        laboratoryName: 'FSSAI Certified Food Analysis Lab',
        reportDate: 'Aug 2026',
        sampleDescription: 'Cold Pressed Mustard Oil CoA',
        ingredients: const [
          DetectedIngredient(name: 'Cold Pressed Mustard Oil (Kachi Ghani)', percentage: 99.8),
          DetectedIngredient(name: 'Natural Vitamin E (Antioxidant)', percentage: 0.2),
        ],
        allergens: const ['Mustard & Mustard Seeds'],
        nutrients: const {
          'Calories': '884',
          'Total Fat': '100',
          'Saturated Fat': '11.6',
          'Monounsaturated Fatty Acids (MUFA)': '59.2',
          'Polyunsaturated Fatty Acids (PUFA)': '21.2',
          'Trans Fat': '0',
          'Sodium': '0',
          'Carbohydrates': '0',
          'Protein': '0',
          'Vitamin E (Tocopherol)': '34',
        },
      );
    } else {
      // Default: Comprehensive Spices / Pickle / General Formulation CoA
      return DetectedLabReportData(
        fileName: file.name,
        laboratoryName: 'Agmark / NABL Accredited Food Analytical Lab',
        reportDate: 'Aug 2026',
        sampleDescription: 'Artisanal Formulation Test Certificate',
        ingredients: const [
          DetectedIngredient(name: 'Raw Mango Pieces (Farm Fresh)', percentage: 61.5),
          DetectedIngredient(name: 'Cold Pressed Mustard Oil', percentage: 18.2),
          DetectedIngredient(name: 'Iodised Salt', percentage: 12.0),
          DetectedIngredient(name: 'Red Chilli Powder (Lal Mirch)', percentage: 4.1),
          DetectedIngredient(name: 'Fenugreek Seeds (Methi)', percentage: 1.8),
          DetectedIngredient(name: 'Turmeric Powder (Haldi)', percentage: 1.4),
          DetectedIngredient(name: 'Asafoetida (Compounded Hing)', percentage: 0.6),
          DetectedIngredient(name: 'Acidity Regulator (INS 260)', percentage: 0.4),
        ],
        allergens: const [
          'Mustard & Mustard Seeds',
          'Wheat / Gluten (in Compounded Hing)',
        ],
        nutrients: const {
          'Calories': '188',
          'Total Fat': '14.5',
          'Saturated Fat': '1.8',
          'Trans Fat': '0',
          'Sodium': '2450',
          'Carbohydrates': '12.4',
          'Dietary Fiber': '3.2',
          'Total Sugars': '2.1',
          'Added Sugars': '0',
          'Protein': '2.2',
          'Vitamin C (Ascorbic Acid)': '18.5',
          'Iron (Fe)': '1.4',
        },
      );
    }
  }
}
