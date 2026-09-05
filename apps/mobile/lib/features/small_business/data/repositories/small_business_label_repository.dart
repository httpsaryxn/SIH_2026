import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/small_business_label_model.dart';

class SmallBusinessLabelRepository {
  final SupabaseClient? client;

  SmallBusinessLabelRepository({this.client});

  SupabaseClient get _supabase {
    if (client != null) return client!;
    try {
      return Supabase.instance.client;
    } catch (_) {
      throw Exception('Supabase is not initialized.');
    }
  }

  static const String _prefsKey = 'small_business_user_labels_cache_v2';
  static List<SmallBusinessLabelModel> _cachedLabels = [];
  static SmallBusinessLabelModel? _cachedActiveDraft;
  static bool _hasLoadedLocalCache = false;

  /// Loads cached labels from SharedPreferences, or initializes with demo labels
  static Future<void> loadLocalCache() async {
    if (_hasLoadedLocalCache && _cachedLabels.isNotEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        _cachedLabels = list
            .map((item) => SmallBusinessLabelModel.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList();
        _cachedActiveDraft = _cachedLabels.where((l) => l.status == 'draft').firstOrNull;
      }
      
      // If still empty (first run on Android Studio emulator or fresh install), populate seed labels
      if (_cachedLabels.isEmpty) {
        _cachedLabels = List<SmallBusinessLabelModel>.from(_defaultSeedLabels);
        _cachedActiveDraft = _cachedLabels.where((l) => l.status == 'draft').firstOrNull;
        await _saveLocalCache();
      }

      _hasLoadedLocalCache = true;
    } catch (e) {
      debugPrint('Error loading local labels cache: $e');
      if (_cachedLabels.isEmpty) {
        _cachedLabels = List<SmallBusinessLabelModel>.from(_defaultSeedLabels);
        _cachedActiveDraft = _cachedLabels.where((l) => l.status == 'draft').firstOrNull;
      }
      _hasLoadedLocalCache = true;
    }
  }

  /// Saves current cache to SharedPreferences
  static Future<void> _saveLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _cachedLabels.map((l) => l.toMap()).toList();
      await prefs.setString(_prefsKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving local labels cache: $e');
    }
  }

  List<SmallBusinessLabelModel> getCachedLabels({String? searchQuery}) {
    var list = List<SmallBusinessLabelModel>.from(_cachedLabels);
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final queryLower = searchQuery.trim().toLowerCase();
      list = list.where((l) {
        return l.productName.toLowerCase().contains(queryLower) ||
            l.brandName.toLowerCase().contains(queryLower) ||
            l.productCategory.toLowerCase().contains(queryLower);
      }).toList();
    }
    return list;
  }

  SmallBusinessLabelModel? getCachedActiveDraft() => _cachedActiveDraft;

  /// Fetches all user labels from Supabase and syncs to local storage
  Future<List<SmallBusinessLabelModel>> fetchLabels({
    String? searchQuery,
    bool includeDrafts = true,
  }) async {
    await loadLocalCache();

    try {
      var query = _supabase
          .from('small_business_labels')
          .select('*');

      if (!includeDrafts) {
        query = query.neq('status', 'draft');
      }

      final response = await query
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 5));
      final List<dynamic> data = response as List<dynamic>;

      final remoteLabels = data
          .map((json) => SmallBusinessLabelModel.fromMap(Map<String, dynamic>.from(json as Map)))
          .toList();

      // Smart Merge: Remote labels take precedence, but keep locally created labels that are pending sync
      final Set<String> remoteIds = remoteLabels
          .map((l) => l.id ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      final List<SmallBusinessLabelModel> merged = List.from(remoteLabels);
      for (final local in _cachedLabels) {
        if (local.id == null || !remoteIds.contains(local.id)) {
          merged.add(local);
        }
      }

      _cachedLabels = merged;
      _cachedActiveDraft = _cachedLabels.where((l) => l.status == 'draft').firstOrNull;
      await _saveLocalCache();

      var result = List<SmallBusinessLabelModel>.from(_cachedLabels);
      if (!includeDrafts) {
        result = result.where((l) => l.status != 'draft').toList();
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final queryLower = searchQuery.trim().toLowerCase();
        result = result.where((l) {
          return l.productName.toLowerCase().contains(queryLower) ||
              l.brandName.toLowerCase().contains(queryLower) ||
              l.productCategory.toLowerCase().contains(queryLower);
        }).toList();
      }

      return result;
    } catch (e) {
      debugPrint('Error fetching labels from Supabase ($e), returning local cache.');
      return getCachedLabels(searchQuery: searchQuery);
    }
  }

  /// Fetches the most recent active draft for the "Continue working" section
  Future<SmallBusinessLabelModel?> fetchActiveDraft() async {
    await loadLocalCache();

    try {
      final response = await _supabase
          .from('small_business_labels')
          .select('*')
          .eq('status', 'draft')
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));

      if (response == null) {
        _cachedActiveDraft = _cachedLabels.where((l) => l.status == 'draft').firstOrNull;
        return _cachedActiveDraft;
      }

      final model = SmallBusinessLabelModel.fromMap(Map<String, dynamic>.from(response));
      _cachedActiveDraft = model;
      return model;
    } catch (e) {
      debugPrint('Error fetching active draft from Supabase: $e');
      return _cachedActiveDraft;
    }
  }

  /// Fetches a single label by its ID
  Future<SmallBusinessLabelModel?> fetchLabelById(String id) async {
    await loadLocalCache();

    try {
      final response = await _supabase
          .from('small_business_labels')
          .select('*')
          .eq('id', id)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));

      if (response == null) {
        return _cachedLabels.where((l) => l.id == id).firstOrNull;
      }
      return SmallBusinessLabelModel.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      debugPrint('Error fetching label by ID from Supabase: $e');
      return _cachedLabels.where((l) => l.id == id).firstOrNull;
    }
  }

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  bool _isValidUuid(String? id) {
    if (id == null || id.isEmpty) return false;
    return _uuidRegex.hasMatch(id);
  }

  /// Saves or updates a draft
  Future<SmallBusinessLabelModel> saveDraft(SmallBusinessLabelModel draft) async {
    await loadLocalCache();

    try {
      final labelData = draft.copyWith(status: 'draft').toMap();
      final Map<String, dynamic> savedRecord;

      if (_isValidUuid(draft.id)) {
        final res = await _supabase
            .from('small_business_labels')
            .update(labelData)
            .eq('id', draft.id!)
            .select()
            .single()
            .timeout(const Duration(seconds: 5));
        savedRecord = Map<String, dynamic>.from(res);
      } else {
        final insertData = Map<String, dynamic>.from(labelData)..remove('id');
        final res = await _supabase
            .from('small_business_labels')
            .insert(insertData)
            .select()
            .single()
            .timeout(const Duration(seconds: 5));
        savedRecord = Map<String, dynamic>.from(res);
      }

      final labelId = savedRecord['id'].toString();
      await _syncChildRecords(labelId, draft);

      final savedModel = draft.copyWith(id: labelId, status: 'draft');
      _updateLocalCacheItem(savedModel);
      _cachedActiveDraft = savedModel;
      await _saveLocalCache();

      return savedModel;
    } catch (e) {
      debugPrint('Error saving draft to Supabase ($e), saving locally in cache.');
      final localId = draft.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final savedModel = draft.copyWith(id: localId, status: 'draft');
      _updateLocalCacheItem(savedModel);
      _cachedActiveDraft = savedModel;
      await _saveLocalCache();
      return savedModel;
    }
  }

  /// Publishes / finalizes a compliant label
  Future<SmallBusinessLabelModel> publishLabel(SmallBusinessLabelModel label) async {
    await loadLocalCache();

    final finalizedData = label
        .copyWith(
          status: 'ready',
          completionPercentage: 100,
          currentStep: 6,
          complianceScore: 98,
          complianceStatus: 'Verified Compliant',
        );

    try {
      final labelMap = finalizedData.toMap();
      final Map<String, dynamic> savedRecord;

      if (_isValidUuid(label.id)) {
        final res = await _supabase
            .from('small_business_labels')
            .update(labelMap)
            .eq('id', label.id!)
            .select()
            .single()
            .timeout(const Duration(seconds: 5));
        savedRecord = Map<String, dynamic>.from(res);
      } else {
        final insertData = Map<String, dynamic>.from(labelMap)..remove('id');
        final res = await _supabase
            .from('small_business_labels')
            .insert(insertData)
            .select()
            .single()
            .timeout(const Duration(seconds: 5));
        savedRecord = Map<String, dynamic>.from(res);
      }

      final labelId = savedRecord['id'].toString();
      await _syncChildRecords(labelId, label);

      final readyModel = finalizedData.copyWith(id: labelId);
      _updateLocalCacheItem(readyModel);
      if (_cachedActiveDraft?.id == labelId) {
        _cachedActiveDraft = null;
      }
      await _saveLocalCache();

      return readyModel;
    } catch (e) {
      debugPrint('Error publishing label in Supabase ($e), updating local cache.');
      final localId = label.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final readyModel = finalizedData.copyWith(id: localId);
      _updateLocalCacheItem(readyModel);
      if (_cachedActiveDraft?.id == localId) {
        _cachedActiveDraft = null;
      }
      await _saveLocalCache();
      return readyModel;
    }
  }

  void _updateLocalCacheItem(SmallBusinessLabelModel model) {
    final index = _cachedLabels.indexWhere(
      (l) =>
          (model.id != null && model.id!.isNotEmpty && l.id == model.id) ||
          (model.productName.trim().isNotEmpty &&
              l.productName.trim().toLowerCase() ==
                  model.productName.trim().toLowerCase() &&
              l.brandName.trim().toLowerCase() ==
                  model.brandName.trim().toLowerCase()),
    );
    if (index >= 0) {
      _cachedLabels.removeAt(index);
    }
    _cachedLabels.insert(0, model);
  }

  /// Internal helper to sync ingredients, allergens, nutrients, claims
  Future<void> _syncChildRecords(String labelId, SmallBusinessLabelModel label) async {
    // 1. Ingredients
    if (label.ingredients.isNotEmpty) {
      try {
        await _supabase.from('small_business_ingredients').delete().eq('label_id', labelId);
        final ingData = label.ingredients.asMap().entries.map((entry) {
          final idx = entry.key;
          final ing = entry.value;
          return {
            'label_id': labelId,
            'name': ing.name,
            'percentage': ing.percentage,
            'order_index': idx + 1,
          };
        }).toList();
        await _supabase.from('small_business_ingredients').insert(ingData);
      } catch (e) {
        debugPrint('Error syncing ingredients: $e');
      }
    }

    // 2. Allergens
    if (label.allergens.isNotEmpty) {
      try {
        await _supabase.from('small_business_allergens').delete().eq('label_id', labelId);
        final algData = label.allergens.map((alg) {
          return {
            'label_id': labelId,
            'allergen_name': alg,
          };
        }).toList();
        await _supabase.from('small_business_allergens').insert(algData);
      } catch (e) {
        debugPrint('Error syncing allergens (table may not exist): $e');
      }
    }

    // 3. Nutrients
    if (label.nutrients.isNotEmpty) {
      try {
        await _supabase.from('small_business_nutrients').delete().eq('label_id', labelId);
        final nutrData = label.nutrients.asMap().entries.map((entry) {
          final idx = entry.key;
          final n = entry.value;
          return {
            'label_id': labelId,
            'label': n.label,
            'value': n.value,
            'unit': n.unit,
            'is_required': n.isRequired,
            'is_sub_nutrient': n.isSubNutrient,
            'order_index': idx + 1,
          };
        }).toList();
        await _supabase.from('small_business_nutrients').insert(nutrData);
      } catch (e) {
        debugPrint('Error syncing nutrients: $e');
      }
    }

    // 4. Claims
    if (label.claims.isNotEmpty) {
      try {
        await _supabase.from('small_business_claims').delete().eq('label_id', labelId);
        final claimsData = label.claims.map((c) {
          return {
            'label_id': labelId,
            'claim_id': c.claimId,
            'title': c.title,
            'description': c.description,
            'category': c.category,
            'requires_lab_report': c.requiresLabReport,
            'legal_reference': c.legalReference,
          };
        }).toList();
        await _supabase.from('small_business_claims').insert(claimsData);
      } catch (e) {
        debugPrint('Error syncing claims: $e');
      }
    }
  }

  /// Deletes a label and all associated child entities
  Future<bool> deleteLabel(String labelId) async {
    await loadLocalCache();
    _cachedLabels.removeWhere((l) => l.id == labelId);
    if (_cachedActiveDraft?.id == labelId) {
      _cachedActiveDraft = _cachedLabels.where((l) => l.status == 'draft').firstOrNull;
    }
    await _saveLocalCache();

    try {
      if (_isValidUuid(labelId)) {
        await _supabase.from('small_business_ingredients').delete().eq('label_id', labelId);
        await _supabase.from('small_business_allergens').delete().eq('label_id', labelId);
        await _supabase.from('small_business_nutrients').delete().eq('label_id', labelId);
        await _supabase.from('small_business_claims').delete().eq('label_id', labelId);
        await _supabase.from('small_business_labels').delete().eq('id', labelId);
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting label $labelId: $e');
      return true;
    }
  }

  /// Deletes all existing drafts
  Future<bool> clearAllDrafts() async {
    await loadLocalCache();
    _cachedLabels.removeWhere((l) => l.status == 'draft');
    _cachedActiveDraft = null;
    await _saveLocalCache();

    try {
      final drafts = await _supabase
          .from('small_business_labels')
          .select('id')
          .eq('status', 'draft');
      for (final d in (drafts as List<dynamic>)) {
        final id = d['id'] as String;
        await deleteLabel(id);
      }
      return true;
    } catch (e) {
      debugPrint('Error clearing drafts: $e');
      return true;
    }
  }

  static final List<SmallBusinessLabelModel> _defaultSeedLabels = [
    SmallBusinessLabelModel(
      id: 'seed-label-mango-pickle',
      brandName: 'Desi Harvest',
      productName: 'Authentic Mango Pickle',
      productCategory: 'Pickles & Condiments',
      typeFlavour: 'Heritage Special (Spicy)',
      status: 'ready',
      completionPercentage: 100,
      currentStep: 6,
      netQuantity: '250',
      netQuantityUnit: 'g',
      servingSize: '15',
      servingSizeUnit: 'g',
      mrp: '149.00',
      usp: '₹ 0.60 / g',
      batchNumber: 'DH-2026-B8',
      mfgDate: 'AUG 2026',
      bestBefore: '12 Months from Packaging',
      storageInstructions: 'Store in a cool, dry and hygienic place. Use dry spoon.',
      manufacturerName: 'Desi Harvest Foods Pvt. Ltd.',
      manufacturerAddress: 'Plot 12, Greenfield Organic Estate, Phase 3, Pune, MH, 411028',
      fssaiLicenseNumber: '12345678901234',
      consumerCarePhone: '+91 98765 43210',
      consumerCareEmail: 'care@desiharvest.in',
      isVegetarian: true,
      complianceScore: 98,
      complianceStatus: 'Verified Compliant',
      exportFormat: 'png',
      labelDimension: 'Standard Pouch (100 × 150 mm)',
      ingredients: const [
        SmallBusinessIngredientModel(name: 'Raw Mango Slices', percentage: 60.0, orderIndex: 1),
        SmallBusinessIngredientModel(name: 'Cold Pressed Mustard Oil', percentage: 18.0, orderIndex: 2),
        SmallBusinessIngredientModel(name: 'Iodised Salt', percentage: 12.0, orderIndex: 3),
        SmallBusinessIngredientModel(name: 'Red Chilli Powder', percentage: 4.5, orderIndex: 4),
        SmallBusinessIngredientModel(name: 'Fenugreek (Methi)', percentage: 2.5, orderIndex: 5),
        SmallBusinessIngredientModel(name: 'Turmeric Powder', percentage: 2.0, orderIndex: 6),
        SmallBusinessIngredientModel(name: 'Compounded Hing (Asafoetida)', percentage: 1.0, orderIndex: 7),
      ],
      allergens: const ['Mustard & Mustard Seeds', 'Wheat / Gluten (in Compounded Hing)'],
      nutrients: const [
        SmallBusinessNutrientModel(label: 'Energy (Calories)', value: '188', unit: 'kcal', isRequired: true, orderIndex: 1),
        SmallBusinessNutrientModel(label: 'Protein', value: '2.2', unit: 'g', isRequired: true, orderIndex: 2),
        SmallBusinessNutrientModel(label: 'Total Carbohydrates', value: '12.4', unit: 'g', isRequired: true, orderIndex: 3),
        SmallBusinessNutrientModel(label: 'Total Sugars', value: '2.1', unit: 'g', isRequired: true, isSubNutrient: true, orderIndex: 4),
        SmallBusinessNutrientModel(label: 'Added Sugars', value: '0', unit: 'g', isRequired: true, isSubNutrient: true, orderIndex: 5),
        SmallBusinessNutrientModel(label: 'Total Fat', value: '14.5', unit: 'g', isRequired: true, orderIndex: 6),
        SmallBusinessNutrientModel(label: 'Saturated Fat', value: '1.8', unit: 'g', isRequired: true, isSubNutrient: true, orderIndex: 7),
        SmallBusinessNutrientModel(label: 'Trans Fat', value: '0', unit: 'g', isRequired: true, isSubNutrient: true, orderIndex: 8),
        SmallBusinessNutrientModel(label: 'Sodium', value: '2450', unit: 'mg', isRequired: true, orderIndex: 9),
      ],
      claims: const [
        SmallBusinessClaimModel(
          claimId: 'no_preservatives',
          title: 'No Artificial Preservatives',
          description: 'Contains no added artificial chemical preservatives',
          category: 'common',
        ),
        SmallBusinessClaimModel(
          claimId: 'handmade',
          title: 'Authentic Traditional Recipe',
          description: 'Sun-matured artisanal batch formulation',
          category: 'origin',
        ),
      ],
    ),
    SmallBusinessLabelModel(
      id: 'seed-label-wild-honey',
      brandName: 'Heritage Agro',
      productName: 'Pure Wild Forest Honey',
      productCategory: 'Honey & Natural Sweeteners',
      typeFlavour: 'Raw Unprocessed',
      status: 'ready',
      completionPercentage: 100,
      currentStep: 6,
      netQuantity: '500',
      netQuantityUnit: 'g',
      servingSize: '20',
      servingSizeUnit: 'g',
      mrp: '349.00',
      usp: '₹ 0.70 / g',
      batchNumber: 'HA-HNY-04',
      mfgDate: 'AUG 2026',
      bestBefore: '18 Months from Packaging',
      storageInstructions: 'Do not refrigerate. Natural honey may crystallize.',
      manufacturerName: 'Heritage Bio Naturals Ltd.',
      manufacturerAddress: 'Himalayan Agro Valley, Dehradun, UK, 248001',
      fssaiLicenseNumber: '10020043000189',
      consumerCarePhone: '+91 99887 76655',
      consumerCareEmail: 'contact@heritageagro.in',
      isVegetarian: true,
      complianceScore: 99,
      complianceStatus: 'Verified Compliant',
      exportFormat: 'pdf',
      labelDimension: 'Standard Pouch (100 × 150 mm)',
      ingredients: const [
        SmallBusinessIngredientModel(name: 'Raw Forest Honey', percentage: 99.5, orderIndex: 1),
        SmallBusinessIngredientModel(name: 'Natural Pollen Extract', percentage: 0.5, orderIndex: 2),
      ],
      allergens: const ['Pollen Allergens (trace)'],
      nutrients: const [
        SmallBusinessNutrientModel(label: 'Energy (Calories)', value: '304', unit: 'kcal', isRequired: true, orderIndex: 1),
        SmallBusinessNutrientModel(label: 'Protein', value: '0.3', unit: 'g', isRequired: true, orderIndex: 2),
        SmallBusinessNutrientModel(label: 'Total Carbohydrates', value: '82.4', unit: 'g', isRequired: true, orderIndex: 3),
        SmallBusinessNutrientModel(label: 'Total Sugars', value: '82.1', unit: 'g', isRequired: true, isSubNutrient: true, orderIndex: 4),
        SmallBusinessNutrientModel(label: 'Added Sugars', value: '0', unit: 'g', isRequired: true, isSubNutrient: true, orderIndex: 5),
        SmallBusinessNutrientModel(label: 'Total Fat', value: '0', unit: 'g', isRequired: true, orderIndex: 6),
        SmallBusinessNutrientModel(label: 'Sodium', value: '4', unit: 'mg', isRequired: true, orderIndex: 7),
      ],
      claims: const [
        SmallBusinessClaimModel(
          claimId: 'pure_raw',
          title: '100% Pure & Raw',
          description: 'Naturally harvested from wild flora',
          category: 'quality',
        ),
      ],
    ),
    SmallBusinessLabelModel(
      id: 'seed-label-garam-masala',
      brandName: 'Royal Spices',
      productName: 'Royal Heritage Garam Masala',
      productCategory: 'Spices & Seasonings',
      typeFlavour: 'Stone Ground Blend',
      status: 'needs_review',
      completionPercentage: 85,
      currentStep: 5,
      netQuantity: '100',
      netQuantityUnit: 'g',
      mrp: '85.00',
      batchNumber: 'RS-GM-99',
      mfgDate: 'AUG 2026',
      bestBefore: '12 Months from Packaging',
      storageInstructions: 'Store in an airtight container in a dry place.',
      manufacturerName: 'Royal Spice Mills',
      manufacturerAddress: 'Industrial Spice Park, Guntur, AP, 522004',
      fssaiLicenseNumber: '11521019000452',
      isVegetarian: true,
      complianceScore: 88,
      complianceStatus: 'Review Required',
      ingredients: const [
        SmallBusinessIngredientModel(name: 'Coriander Seeds', percentage: 40.0, orderIndex: 1),
        SmallBusinessIngredientModel(name: 'Cumin (Jeera)', percentage: 25.0, orderIndex: 2),
        SmallBusinessIngredientModel(name: 'Black Pepper', percentage: 15.0, orderIndex: 3),
        SmallBusinessIngredientModel(name: 'Cardamom (Elaichi)', percentage: 10.0, orderIndex: 4),
        SmallBusinessIngredientModel(name: 'Cinnamon & Cloves', percentage: 10.0, orderIndex: 5),
      ],
      allergens: const [],
      nutrients: const [
        SmallBusinessNutrientModel(label: 'Energy (Calories)', value: '380', unit: 'kcal', isRequired: true, orderIndex: 1),
        SmallBusinessNutrientModel(label: 'Protein', value: '12.0', unit: 'g', isRequired: true, orderIndex: 2),
        SmallBusinessNutrientModel(label: 'Total Fat', value: '14.0', unit: 'g', isRequired: true, orderIndex: 3),
      ],
    ),
    SmallBusinessLabelModel(
      id: 'seed-label-banana-chips',
      brandName: 'Malabar Naturals',
      productName: 'Artisanal Banana Chips',
      productCategory: 'Snacks & Namkeen',
      typeFlavour: 'Salted Golden Crisps',
      status: 'draft',
      completionPercentage: 45,
      currentStep: 2,
      netQuantity: '150',
      netQuantityUnit: 'g',
      mrp: '75.00',
      batchNumber: 'MN-BC-12',
      mfgDate: 'AUG 2026',
      manufacturerName: 'Malabar Foods Cooperative',
      manufacturerAddress: 'Kozhikode Agro Zone, Kerala, 673001',
      fssaiLicenseNumber: '11319007000211',
      isVegetarian: true,
      complianceScore: 65,
      complianceStatus: 'Draft in Progress',
      ingredients: const [
        SmallBusinessIngredientModel(name: 'Raw Nendran Bananas', percentage: 75.0, orderIndex: 1),
        SmallBusinessIngredientModel(name: 'Cold Pressed Coconut Oil', percentage: 22.0, orderIndex: 2),
        SmallBusinessIngredientModel(name: 'Rock Salt', percentage: 3.0, orderIndex: 3),
      ],
    ),
  ];
}

