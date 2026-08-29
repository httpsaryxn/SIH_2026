import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/small_business_label_model.dart';

class SmallBusinessLabelRepository {
  final SupabaseClient? _client;

  SmallBusinessLabelRepository({SupabaseClient? client})
      : _client = client;

  SupabaseClient get _supabase {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      throw Exception('Supabase is not initialized.');
    }
  }

  /// Fetches all completed or under-review labels (excluding raw in-progress drafts)
  Future<List<SmallBusinessLabelModel>> fetchLabels({String? searchQuery}) async {
    try {
      var query = _supabase
          .from('small_business_labels')
          .select('''
            *,
            ingredients:small_business_ingredients(*),
            allergens:small_business_allergens(*),
            nutrients:small_business_nutrients(*),
            claims:small_business_claims(*)
          ''')
          .neq('status', 'draft')
          .order('created_at', ascending: false);

      final response = await query;
      final List<dynamic> data = response as List<dynamic>;

      var labels = data
          .map((json) => SmallBusinessLabelModel.fromMap(Map<String, dynamic>.from(json as Map)))
          .toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final queryLower = searchQuery.trim().toLowerCase();
        labels = labels.where((l) {
          return l.productName.toLowerCase().contains(queryLower) ||
              l.brandName.toLowerCase().contains(queryLower) ||
              l.productCategory.toLowerCase().contains(queryLower);
        }).toList();
      }

      return labels;
    } catch (e) {
      debugPrint('Error fetching labels from Supabase: $e');
      return [];
    }
  }

  /// Fetches the most recent active draft for the "Continue working" section
  Future<SmallBusinessLabelModel?> fetchActiveDraft() async {
    try {
      final response = await _supabase
          .from('small_business_labels')
          .select('''
            *,
            ingredients:small_business_ingredients(*),
            allergens:small_business_allergens(*),
            nutrients:small_business_nutrients(*),
            claims:small_business_claims(*)
          ''')
          .eq('status', 'draft')
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return SmallBusinessLabelModel.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      debugPrint('Error fetching active draft from Supabase: $e');
      return null;
    }
  }

  /// Fetches a single label by its ID
  Future<SmallBusinessLabelModel?> fetchLabelById(String id) async {
    try {
      final response = await _supabase
          .from('small_business_labels')
          .select('''
            *,
            ingredients:small_business_ingredients(*),
            allergens:small_business_allergens(*),
            nutrients:small_business_nutrients(*),
            claims:small_business_claims(*)
          ''')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return SmallBusinessLabelModel.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      debugPrint('Error fetching label by ID from Supabase: $e');
      return null;
    }
  }

  /// Saves or updates a draft
  Future<SmallBusinessLabelModel> saveDraft(SmallBusinessLabelModel draft) async {
    try {
      final labelData = draft.copyWith(status: 'draft').toMap();
      final Map<String, dynamic> savedRecord;

      if (draft.id != null && draft.id!.isNotEmpty) {
        final res = await _supabase
            .from('small_business_labels')
            .update(labelData)
            .eq('id', draft.id!)
            .select()
            .single();
        savedRecord = Map<String, dynamic>.from(res);
      } else {
        final res = await _supabase
            .from('small_business_labels')
            .insert(labelData)
            .select()
            .single();
        savedRecord = Map<String, dynamic>.from(res);
      }

      final labelId = savedRecord['id'].toString();

      // Sync child records
      await _syncChildRecords(labelId, draft);

      return draft.copyWith(id: labelId, status: 'draft');
    } catch (e) {
      debugPrint('Error saving draft in Supabase: $e');
      rethrow;
    }
  }

  /// Publishes / finalizes a compliant label
  Future<SmallBusinessLabelModel> publishLabel(SmallBusinessLabelModel label) async {
    try {
      final finalizedData = label
          .copyWith(
            status: 'ready',
            completionPercentage: 100,
            currentStep: 6,
            complianceScore: 98,
            complianceStatus: 'Verified Compliant',
          )
          .toMap();

      final Map<String, dynamic> savedRecord;

      if (label.id != null && label.id!.isNotEmpty) {
        final res = await _supabase
            .from('small_business_labels')
            .update(finalizedData)
            .eq('id', label.id!)
            .select()
            .single();
        savedRecord = Map<String, dynamic>.from(res);
      } else {
        final res = await _supabase
            .from('small_business_labels')
            .insert(finalizedData)
            .select()
            .single();
        savedRecord = Map<String, dynamic>.from(res);
      }

      final labelId = savedRecord['id'].toString();

      // Sync child records
      await _syncChildRecords(labelId, label);

      return label.copyWith(
        id: labelId,
        status: 'ready',
        completionPercentage: 100,
        currentStep: 6,
      );
    } catch (e) {
      debugPrint('Error publishing label in Supabase: $e');
      rethrow;
    }
  }

  /// Internal helper to sync ingredients, allergens, nutrients, claims
  Future<void> _syncChildRecords(String labelId, SmallBusinessLabelModel label) async {
    try {
      // 1. Ingredients
      if (label.ingredients.isNotEmpty) {
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
      }

      // 2. Allergens
      if (label.allergens.isNotEmpty) {
        await _supabase.from('small_business_allergens').delete().eq('label_id', labelId);
        final algData = label.allergens.map((alg) {
          return {
            'label_id': labelId,
            'allergen_name': alg,
          };
        }).toList();
        await _supabase.from('small_business_allergens').insert(algData);
      }

      // 3. Nutrients
      if (label.nutrients.isNotEmpty) {
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
      }

      // 4. Claims
      if (label.claims.isNotEmpty) {
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
      }
    } catch (e) {
      debugPrint('Error syncing child records for label $labelId: $e');
    }
  }

  /// Deletes a label and all associated child entities
  Future<bool> deleteLabel(String labelId) async {
    try {
      await _supabase.from('small_business_ingredients').delete().eq('label_id', labelId);
      await _supabase.from('small_business_allergens').delete().eq('label_id', labelId);
      await _supabase.from('small_business_nutrients').delete().eq('label_id', labelId);
      await _supabase.from('small_business_claims').delete().eq('label_id', labelId);
      await _supabase.from('small_business_labels').delete().eq('id', labelId);
      return true;
    } catch (e) {
      debugPrint('Error deleting label $labelId: $e');
      return false;
    }
  }

  /// Deletes all existing drafts
  Future<bool> clearAllDrafts() async {
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
      return false;
    }
  }
}

