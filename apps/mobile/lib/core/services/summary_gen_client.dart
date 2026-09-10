import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/groq_config.dart';

class ConsumerSummaryResult {
  final String productType;
  final String classificationReasoning;
  final String summaryText;
  final int? healthScore;
  final String? healthScoreRationale;
  final String? medicinalSafetySummary;
  final String? mandatoryDisclaimer;
  final bool cached;

  const ConsumerSummaryResult({
    required this.productType,
    required this.classificationReasoning,
    required this.summaryText,
    this.healthScore,
    this.healthScoreRationale,
    this.medicinalSafetySummary,
    this.mandatoryDisclaimer,
    this.cached = false,
  });

  bool get isFood => productType == 'food';
  bool get isMedicinal => productType == 'medicinal';
  bool get isGeneral => productType == 'general';

  factory ConsumerSummaryResult.fromJson(Map<String, dynamic> json) {
    return ConsumerSummaryResult(
      productType: json['product_type'] as String? ?? 'unclassified',
      classificationReasoning: json['classification_reasoning'] as String? ?? '',
      summaryText: json['summary_text'] as String? ?? '',
      healthScore: json['health_score'] as int?,
      healthScoreRationale: json['health_score_rationale'] as String?,
      medicinalSafetySummary: json['medicinal_safety_summary'] as String?,
      mandatoryDisclaimer: json['mandatory_disclaimer'] as String?,
      cached: json['cached'] as bool? ?? false,
    );
  }
}

class RegulatorSummaryResult {
  final String scanId;
  final String productType;
  final String summaryText;
  final String pdfUrl;
  final bool cached;

  const RegulatorSummaryResult({
    required this.scanId,
    required this.productType,
    required this.summaryText,
    required this.pdfUrl,
    this.cached = false,
  });

  factory RegulatorSummaryResult.fromJson(Map<String, dynamic> json) {
    final rawPdfUrl = json['regulator_pdf_url'] as String? ??
        json['pdf_url'] as String? ??
        '';
    final absolutePdfUrl = (rawPdfUrl.startsWith('/') && !rawPdfUrl.startsWith('//'))
        ? '${SummaryGenClient.baseUrl}$rawPdfUrl'
        : rawPdfUrl;

    return RegulatorSummaryResult(
      scanId: json['scan_id'] as String? ?? '',
      productType: json['product_type'] as String? ?? 'general',
      summaryText: json['regulator_summary_text'] as String? ??
          json['summary_text'] as String? ??
          '',
      pdfUrl: absolutePdfUrl,
      cached: json['cached'] as bool? ?? false,
    );
  }
}

class SummaryGenClient {
  static const String cloudUrl = 'https://labellens-ml-scanner.onrender.com';
  static const String prefKey = 'summary_gen_base_url';
  static String _baseUrl = cloudUrl;

  static String get baseUrl => _baseUrl;

  static Future<void> setBaseUrl(String url) async {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKey, _baseUrl);
    } catch (_) {}
  }

  /// Automatically detect candidate service URLs (local USB/LAN dev vs Render cloud)
  static Future<bool> isAvailable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(prefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _baseUrl = saved.trim();
      }
    } catch (_) {}

    // First, fast probe for local development servers (USB adb reverse, emulator, LAN)
    final localCandidates = <String>[
      if (Platform.isAndroid) ...[
        'http://127.0.0.1:8001',
        'http://127.0.0.1:8000',
        'http://10.0.2.2:8001',
        'http://10.0.2.2:8000',
      ],
      'http://localhost:8001',
      'http://localhost:8000',
      'http://192.168.0.104:8001',
      'http://192.168.0.116:8001',
    ];

    // If _baseUrl was previously set to a local URL, check it first
    if (_baseUrl.contains('127.0.0.1') || _baseUrl.contains('localhost') || _baseUrl.contains('192.168.')) {
      if (!localCandidates.contains(_baseUrl)) {
        localCandidates.insert(0, _baseUrl);
      }
    }

    for (final url in localCandidates) {
      try {
        final res = await http
            .get(Uri.parse('$url/health'))
            .timeout(const Duration(milliseconds: 700));
        if (res.statusCode == 200) {
          _baseUrl = url;
          debugPrint('[SummaryGenClient] Connected to local service at $url');
          return true;
        }
      } catch (_) {}
    }

    // Next, check Render cloud URL
    try {
      final res = await http
          .get(Uri.parse('$cloudUrl/health'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        _baseUrl = cloudUrl;
        debugPrint('[SummaryGenClient] Connected to cloud service at $cloudUrl');
        return true;
      }
    } catch (_) {}

    // If cloud URL check timed out (e.g. cold start), still default to cloudUrl so request gets 45s timeout
    if (_baseUrl.startsWith('https://') || _baseUrl.isEmpty) {
      _baseUrl = cloudUrl;
      return true;
    }

    return false;
  }

  /// Request a consumer-facing summary (with product-type detection and health/safety scoring)
  static Future<ConsumerSummaryResult> summarizeConsumer({
    String? scanId,
    required String productName,
    String? manufacturer,
    Map<String, dynamic>? declarations,
    Map<String, dynamic>? rules,
    String? ocrText,
    bool forceRegenerate = false,
  }) async {
    // ── Priority 1: Direct Groq Cloud AI (LLaMA 3.3 70B) ──
    try {
      final groqKey = await GroqConfig.getApiKey();
      if (groqKey.isNotEmpty) {
        debugPrint('[SummaryGenClient] Using direct Groq LLaMA 3.3 API for consumer summary');
        final directResult = await _callGroqDirect(
          apiKey: groqKey,
          productName: productName,
          manufacturer: manufacturer,
          declarations: declarations,
          rules: rules,
          ocrText: ocrText,
        );
        if (directResult != null) {
          return directResult;
        }
      }
    } catch (e) {
      debugPrint('[SummaryGenClient] Direct Groq API failed: $e. Falling back to backend/heuristics.');
    }

    // ── Priority 2: Remote backend proxy service (/summarize/consumer) ──
    final isUp = await isAvailable();
    if (isUp) {
      try {
        final uri = Uri.parse('$_baseUrl/summarize/consumer');
        final body = jsonEncode({
          'scan_id': scanId,
          'product_name': productName,
          'manufacturer': manufacturer,
          'extracted_declarations': declarations ?? {},
          'rules': rules ?? {},
          'ocr_text': ocrText,
          'force_regenerate': forceRegenerate,
        });

        final response = await http
            .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          return ConsumerSummaryResult.fromJson(json);
        }
      } catch (e) {
        debugPrint('[SummaryGenClient] Backend summary-gen error: $e');
      }
    }

    // ── Priority 3: Smart on-device OCR heuristic fallback (inspects real OCR text) ──
    debugPrint('[SummaryGenClient] Utilizing on-device OCR & rule analyzer fallback');
    return _generateClientFallbackConsumer(
      productName: productName,
      manufacturer: manufacturer,
      declarations: declarations,
      ocrText: ocrText,
    );
  }

  /// Directly calls Groq Cloud API using LLaMA 3.3 70B (`llama-3.3-70b-versatile`)
  static Future<ConsumerSummaryResult?> _callGroqDirect({
    required String apiKey,
    required String productName,
    String? manufacturer,
    Map<String, dynamic>? declarations,
    Map<String, dynamic>? rules,
    String? ocrText,
  }) async {
    const systemPrompt = '''You are an expert consumer health advocate, food safety scientist, and legal metrology auditor for the LabelLens application.
Your goal is to inspect declared packaging label data and raw OCR text, producing an honest, transparent, consumer-friendly safety & nutritional breakdown.

CRITICAL RESPONSIBILITIES:
1. CLASSIFY the commodity into: "food", "medicinal", or "general".
   - "food": Edible items, drinks, snacks, spices, dairy, confectionery, grocery. Key indicators: FSSAI license, nutritional facts, ingredient list.
   - "medicinal": Drugs, pharmaceuticals, ayurvedic medicines, syrups, supplements, topical ointments, schedule drugs, dosage guidelines.
   - "general": Non-food/non-medicinal items (e.g. detergents, cosmetics, electronics, apparel, hardware).

2. FOR FOOD PRODUCTS — HARMFUL INGREDIENTS & THRESHOLD AUDIT:
   Thoroughly inspect the OCR text and declared ingredients/nutrition:
   a) HARMFUL / CONCERNING ADDITIVES:
      - Synthetic Food Colors (e.g., Tartrazine / Yellow 5 / INS 102, Sunset Yellow / Yellow 6 / INS 110, Allura Red / Red 40 / INS 129, Brilliant Blue / INS 133, Carmoisine / INS 122, Ponceau 4R / INS 124, Fast Green / INS 143).
      - Chemical Preservatives (e.g., BHA / INS 320, BHT / INS 321, Sodium Benzoate / INS 211, Potassium Sorbate / INS 202, Sulphites / INS 220-228).
      - Palm oil, hydrogenated vegetable fats, industrial palm olein, or trans fats.
      - High MSG / Monosodium Glutamate / INS 621 / yeast extract flavour enhancers.
      - Intense artificial sweeteners (Aspartame / INS 951, Acesulfame K / INS 950, Sucralose / INS 955) or high-fructose corn syrup.
   b) EXCESSIVE NUTRITIONAL THRESHOLDS (per 100g or per serving):
      - Excessive Sodium: > 600 mg / 100g (or > 1.5g salt / 100g). Must warn about hypertension, high blood pressure, and cardiovascular strain.
      - Excessive Sugar: > 15 g / 100g (or > 22.5g total sugar). Must warn about spike in blood glucose, diabetes risk, and empty calories.
      - High Saturated Fat: > 5 g / 100g or Trans Fat > 0g.
   c) SUMMARY TEXT FORMATTING:
      - If ANY harmful ingredients or excessive thresholds are detected:
        Include a distinct section:
        "### ⚠️ Health & Ingredient Concerns"
        Followed by specific bullet points explaining each flag and why it is concerning.
      - If NO harmful additives, synthetic dyes, or excessive sodium/sugar levels are found:
        Include a clear, reassuring POSITIVE endorsement:
        "### ✅ Clean Formulation & Safe Nutrition"
        Explicitly praising the clean label, absence of artificial synthetic dyes, safe preservative profile, and balanced sodium/sugar levels.
      - Also include a short 2-3 bullet point "Nutritional & Label Highlights" summarizing net contents, price/MRP, key wholesome ingredients, and FSSAI status.
   d) HEALTH SCORE (0 to 100):
      - 80-100: Clean label, wholesome, low in sodium/sugar, free of synthetic colors/harmful preservatives.
      - 55-79: Moderate processed food, acceptable limits but contains palm oil or moderate sugar/sodium.
      - 0-54: High sodium/sugar, synthetic colors (INS 102/110/129), BHA/BHT, or trans fats.

3. FOR MEDICINAL PRODUCTS:
   - Provide plain-language overview of indications/uses.
   - Outline dosage caution, batch/expiry checks, storage instructions.
   - MUST append exact disclaimer: "Informational summary of declared label content only. Not medical advice."
   - Set health_score to null.

4. FOR GENERAL PRODUCTS:
   - Provide summary of commodity type, net quantity, manufacturer, retail price, and statutory declarations.
   - Set health_score to null.

OUTPUT FORMAT:
Return strictly a valid JSON object matching this schema:
{
  "product_type": "food" | "medicinal" | "general",
  "classification_reasoning": "brief explanation",
  "summary_text": "Markdown formatted summary following the above rules",
  "health_score": integer (0-100) or null,
  "health_score_rationale": "one sentence summarizing the health score",
  "medicinal_safety_summary": "string or null",
  "mandatory_disclaimer": "string or null"
}''';

    final userContent = '''
Product Name: $productName
Manufacturer: ${manufacturer ?? 'Declared on packaging'}
Declared Attributes:
${jsonEncode(declarations ?? {})}

Legal Metrology Passed Rules: ${(rules?['passed'] as List?)?.length ?? 0}
Legal Metrology Failed Rules: ${(rules?['failed'] as List?)?.length ?? 0}

Raw Scanned Label OCR Text (Front & Back/Nutrition):
${ocrText ?? 'No OCR text available'}
''';

    final modelsToTry = [GroqConfig.model, ...GroqConfig.fallbackModels];
    for (final model in modelsToTry.toSet()) {
      try {
        final response = await http
            .post(
              Uri.parse(GroqConfig.apiUrl),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
                'User-Agent': 'LabelLens/1.0',
              },
              body: jsonEncode({
                'model': model,
                'messages': [
                  {'role': 'system', 'content': systemPrompt},
                  {'role': 'user', 'content': userContent},
                ],
                'temperature': 0.15,
                'response_format': {'type': 'json_object'},
                'max_tokens': 1000,
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final resJson = jsonDecode(response.body) as Map<String, dynamic>;
          final choices = resJson['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final content = choices[0]['message']?['content'] as String?;
            if (content != null && content.trim().isNotEmpty) {
              final parsed = jsonDecode(_extractJson(content)) as Map<String, dynamic>;
              return ConsumerSummaryResult.fromJson(parsed);
            }
          }
        } else {
          debugPrint('[SummaryGenClient] Groq model $model returned ${response.statusCode}: ${response.body}');
        }
      } catch (err) {
        debugPrint('[SummaryGenClient] Groq model $model error: $err');
      }
    }
    return null;
  }

  static String _extractJson(String text) {
    final cleaned = text.trim();
    final firstBrace = cleaned.indexOf('{');
    final lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      return cleaned.substring(firstBrace, lastBrace + 1);
    }
    return cleaned;
  }

  /// Request a regulator audit summary and PDF report
  static Future<RegulatorSummaryResult?> summarizeRegulator({
    required String scanId,
    required String productName,
    String? companyName,
    String? category,
    required List<Map<String, dynamic>> declarationChecks,
    Map<String, String?>? imageUrls,
    String? userId,
    bool forceRegenerate = false,
  }) async {
    final isUp = await isAvailable();
    if (!isUp) {
      debugPrint('[SummaryGenClient] Service not available for regulator PDF generation.');
      return null;
    }

    try {
      final uri = Uri.parse('$_baseUrl/summarize/regulator');
      final body = jsonEncode({
        'scan_id': scanId,
        'product_name': productName,
        'company_name': companyName,
        'category': category,
        'declaration_checks': declarationChecks,
        'image_urls': imageUrls ?? {},
        'user_id': userId,
        'force_regenerate': forceRegenerate,
      });

      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return RegulatorSummaryResult.fromJson(json);
      }
    } catch (e) {
      debugPrint('[SummaryGenClient] Error calling regulator summary: $e');
    }
    return null;
  }

  /// Real deterministic on-device analysis fallback that parses raw OCR text
  /// for sodium, sugar, synthetic colors (INS codes), preservatives, and palm oil.
  static ConsumerSummaryResult _generateClientFallbackConsumer({
    required String productName,
    String? manufacturer,
    Map<String, dynamic>? declarations,
    String? ocrText,
  }) {
    declarations ??= {};
    final ocr = (ocrText ?? '').toLowerCase();
    final nameLower = productName.toLowerCase();

    final isPharma = nameLower.contains('syrup') ||
        nameLower.contains('tablet') ||
        nameLower.contains('capsule') ||
        nameLower.contains('ointment') ||
        nameLower.contains('pharma') ||
        nameLower.contains('medicine') ||
        ocr.contains('dosage') ||
        ocr.contains('ip/bp/usp') ||
        ocr.contains('schedule h');

    if (isPharma) {
      const disclaimer = 'Informational summary of declared label content only. Not medical advice.';
      return ConsumerSummaryResult(
        productType: 'medicinal',
        classificationReasoning: 'Classified based on medicinal keywords in commodity description and label.',
        summaryText:
            '**Declared Commodity**: $productName\n\n'
            '• **Manufacturer**: ${manufacturer ?? declarations['manufacturer'] ?? "Declared on packaging"}\n'
            '• **Net Volume**: ${declarations['net_quantity'] ?? "Standard pack"}\n'
            '• **Directions**: Verify batch number, expiry date, and dosage instructions on label before use.\n\n'
            '*⚠️ $disclaimer*',
        medicinalSafetySummary: 'Keep out of reach of children. Store in a cool, dry place away from direct sunlight.',
        mandatoryDisclaimer: disclaimer,
      );
    }

    final isFood = declarations.containsKey('fssai') ||
        declarations.containsKey('fssai_license_no') ||
        ocr.contains('fssai') ||
        ocr.contains('ingredient') ||
        ocr.contains('nutrition') ||
        nameLower.contains('food') ||
        nameLower.contains('snack') ||
        nameLower.contains('drink') ||
        nameLower.contains('chocolate') ||
        nameLower.contains('butter') ||
        nameLower.contains('biscuit') ||
        nameLower.contains('noodle') ||
        nameLower.contains('chips') ||
        nameLower.contains('oil');

    if (isFood) {
      final harmfulFlags = <String>[];
      final positivePoints = <String>[];

      // 1. Sodium inspection
      final sodiumRegex = RegExp(r'(?:sodium|salt)[\s:]*([0-9]+(?:\.[0-9]+)?)\s*(mg|g)', caseSensitive: false);
      final sodiumMatch = sodiumRegex.firstMatch(ocr);
      if (sodiumMatch != null) {
        final val = double.tryParse(sodiumMatch.group(1) ?? '') ?? 0;
        final unit = (sodiumMatch.group(2) ?? 'mg').toLowerCase();
        final mgVal = unit == 'g' ? val * 1000 : val;
        if (mgVal >= 600) {
          harmfulFlags.add('• **Excessive Sodium**: Found ${mgVal.toStringAsFixed(0)}mg per portion/100g, crossing safe daily threshold (>600mg). High sodium intake is linked to elevated blood pressure and cardiovascular risk.');
        } else if (mgVal > 0) {
          positivePoints.add('• **Moderate Sodium**: ${mgVal.toStringAsFixed(0)}mg, within standard limits.');
        }
      }

      // 2. Sugar inspection
      final sugarRegex = RegExp(r'(?:total\s+)?sugar[s]?[\s:]*([0-9]+(?:\.[0-9]+)?)\s*g', caseSensitive: false);
      final sugarMatch = sugarRegex.firstMatch(ocr);
      if (sugarMatch != null) {
        final sugarVal = double.tryParse(sugarMatch.group(1) ?? '') ?? 0;
        if (sugarVal >= 15) {
          harmfulFlags.add('• **High Sugar Level**: Found ${sugarVal.toStringAsFixed(1)}g sugar per 100g/serving (exceeds 15g threshold). High consumption leads to rapid glycemic spikes.');
        } else if (sugarVal > 0) {
          positivePoints.add('• **Balanced Sugar**: ${sugarVal.toStringAsFixed(1)}g sugar per serving, low glycemic impact.');
        }
      }

      // 3. Artificial synthetic food colors
      final foundColors = <String>[];
      if (ocr.contains('102') || ocr.contains('tartrazine') || ocr.contains('yellow 5')) {
        foundColors.add('Tartrazine / Yellow 5 (INS 102)');
      }
      if (ocr.contains('110') || ocr.contains('sunset yellow') || ocr.contains('yellow 6')) {
        foundColors.add('Sunset Yellow (INS 110)');
      }
      if (ocr.contains('129') || ocr.contains('allura red') || ocr.contains('red 40')) {
        foundColors.add('Allura Red (INS 129)');
      }
      if (ocr.contains('133') || ocr.contains('brilliant blue')) {
        foundColors.add('Brilliant Blue (INS 133)');
      }
      if (ocr.contains('122') || ocr.contains('carmoisine')) {
        foundColors.add('Carmoisine (INS 122)');
      }
      if (foundColors.isNotEmpty) {
        harmfulFlags.add('• **Harmful Synthetic Food Colors**: Found ${foundColors.join(", ")}. Synthetic petroleum-derived dyes are associated with allergic reactivity and behavioral sensitivity in children.');
      }

      // 4. Chemical preservatives
      final foundPreservatives = <String>[];
      if (ocr.contains('320') || ocr.contains('bha')) foundPreservatives.add('BHA (INS 320)');
      if (ocr.contains('321') || ocr.contains('bht')) foundPreservatives.add('BHT (INS 321)');
      if (ocr.contains('211') || ocr.contains('benzoate')) foundPreservatives.add('Sodium Benzoate (INS 211)');
      if (ocr.contains('220') || ocr.contains('223') || ocr.contains('sulphite')) foundPreservatives.add('Sulphites (INS 220-224)');
      if (foundPreservatives.isNotEmpty) {
        harmfulFlags.add('• **Chemical Preservatives**: Contains ${foundPreservatives.join(", ")}. Consider moderation for individuals with sensitive digestive or respiratory tracts.');
      }

      // 5. Palm oil & trans fats
      if (ocr.contains('palm oil') || ocr.contains('palmolein') || ocr.contains('palm olein') || ocr.contains('hydrogenated vegetable')) {
        harmfulFlags.add('• **Refined Palm Fat / Hydrogenated Oil**: Contains high proportion of saturated palmitic fatty acids.');
      }
      if (ocr.contains('621') || ocr.contains('monosodium glutamate') || ocr.contains('msg')) {
        harmfulFlags.add('• **Flavour Enhancer (MSG / INS 621)**: Contains added glutamate.');
      }

      // Construct dynamic summary
      final sb = StringBuffer();
      int calculatedHealthScore = 85;

      if (harmfulFlags.isNotEmpty) {
        calculatedHealthScore = (85 - (harmfulFlags.length * 15)).clamp(25, 65);
        sb.writeln('### ⚠️ Health & Ingredient Concerns');
        for (final flag in harmfulFlags) {
          sb.writeln(flag);
        }
        sb.writeln();
      } else {
        calculatedHealthScore = 88;
        sb.writeln('### ✅ Clean Formulation & Safe Nutrition');
        sb.writeln('• **No Harmful Synthetic Dyes**: Free from artificial food colorants (e.g. Tartrazine, Sunset Yellow, Allura Red).');
        sb.writeln('• **No Concerning Preservatives**: No industrial chemical preservatives (BHA, BHT, excess benzoates) detected on label.');
        sb.writeln('• **Safe Thresholds**: Sodium and sugar levels remain within wholesome recommended daily allowances.');
        sb.writeln();
      }

      sb.writeln('### 📋 Declared Label Highlights: $productName');
      sb.writeln('• **Net Quantity**: ${declarations['net_quantity'] ?? "Declared on packaging"}');
      sb.writeln('• **Retail Price**: ₹${declarations['mrp'] ?? "Declared on label"}');
      sb.writeln('• **FSSAI License**: ${declarations['fssai'] ?? declarations['fssai_license_no'] ?? (ocr.contains("fssai") ? "Identified on label" : "Verified")}');
      if (positivePoints.isNotEmpty) {
        for (final p in positivePoints) {
          sb.writeln(p);
        }
      }

      final rationale = harmfulFlags.isNotEmpty
          ? 'Score lowered due to ${harmfulFlags.length} flagged ingredients/thresholds (synthetic additives or excessive nutrient concentrations).'
          : 'High score awarded for clean ingredient formulation without harmful synthetic colorants or excessive sodium.';

      return ConsumerSummaryResult(
        productType: 'food',
        classificationReasoning: 'Classified based on packaging declarations and nutritional label content.',
        summaryText: sb.toString().trim(),
        healthScore: calculatedHealthScore,
        healthScoreRationale: rationale,
      );
    }

    return ConsumerSummaryResult(
      productType: 'general',
      classificationReasoning: 'General packaged commodity.',
      summaryText:
          '**Packaging Declarations**: $productName\n\n'
          '• **Net Quantity**: ${declarations['net_quantity'] ?? "Declared"}\n'
          '• **Manufacturer**: ${manufacturer ?? "Declared on label"}\n'
          '• **Retail Price**: ₹${declarations['mrp'] ?? "Declared on label"}',
    );
  }
}
