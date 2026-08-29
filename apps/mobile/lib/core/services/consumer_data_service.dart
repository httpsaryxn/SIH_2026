import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/consumer_complaint_model.dart';
import '../models/consumer_saved_product.dart';
import '../models/consumer_scan_model.dart';
import '../models/product_model.dart';
import 'auth_service.dart';

class ConsumerDataService {
  static SupabaseClient get _client => Supabase.instance.client;

  static String? get _userId => AuthService.currentUser?.id;

  /// Fetch all products from catalog
  static Future<List<ProductModel>> fetchProductsCatalog() async {
    try {
      final data = await _client
          .from('products')
          .select()
          .order('created_at', ascending: false);

      return (data as List).map((e) => ProductModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch recent scans for current consumer (with automatic initial seeding if empty)
  static Future<List<ConsumerScanModel>> fetchRecentScans() async {
    final uid = _userId;
    if (uid == null) return [];

    try {
      final data = await _client
          .from('consumer_scans')
          .select()
          .eq('consumer_id', uid)
          .order('scanned_at', ascending: false);

      if ((data as List).isNotEmpty) {
        return data.map((e) => ConsumerScanModel.fromJson(e)).toList();
      }

      // If empty for this user, seed 2 initial demo scans from the products catalog
      final products = await fetchProductsCatalog();
      if (products.isNotEmpty) {
        final sourdough = products.firstWhere(
          (p) => p.productName.contains('Sourdough'),
          orElse: () => products[0],
        );
        final choco = products.firstWhere(
          (p) => p.productName.contains('Choco'),
          orElse: () => products.length > 1 ? products[1] : products[0],
        );

        final scan1 = await recordScan(
          product: sourdough,
          customTime: DateTime.now().subtract(const Duration(hours: 2)),
        );
        final scan2 = await recordScan(
          product: choco,
          customTime: DateTime.now().subtract(const Duration(days: 1)),
        );

        return [
          ?scan1,
          ?scan2,
        ];
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Record a new scan in Supabase
  static Future<ConsumerScanModel?> recordScan({
    required ProductModel product,
    DateTime? customTime,
  }) async {
    final uid = _userId;
    if (uid == null) return null;

    try {
      final insertData = {
        'consumer_id': uid,
        'product_id': product.id,
        'product_name': product.productName,
        'brand': product.brand,
        'net_quantity': product.netQuantity ?? '1 unit',
        'image_url': product.imageUrl,
        'compliance_status': product.complianceStatus,
        'detected_declarations': {
          'ingredients': product.ingredients,
          'nutrition_facts': product.nutritionFacts,
          'manufacturer': product.manufacturerName,
        },
        'scan_notes': product.complianceIssues.isNotEmpty
            ? product.complianceIssues.first['message']
            : 'All mandatory Legal Metrology declarations verified.',
        'scanned_at': (customTime ?? DateTime.now()).toIso8601String(),
      };

      final res = await _client
          .from('consumer_scans')
          .insert(insertData)
          .select()
          .single();

      return ConsumerScanModel.fromJson(res);
    } catch (e) {
      return null;
    }
  }

  /// Fetch saved/bookmarked products
  static Future<List<ConsumerSavedProduct>> fetchSavedProducts() async {
    final uid = _userId;
    if (uid == null) return [];

    try {
      final data = await _client
          .from('saved_products')
          .select()
          .eq('consumer_id', uid)
          .order('saved_at', ascending: false);

      if ((data as List).isNotEmpty) {
        return data.map((e) => ConsumerSavedProduct.fromJson(e)).toList();
      }

      // Seed initial demo bookmarks if empty
      final products = await fetchProductsCatalog();
      if (products.isNotEmpty) {
        final almondMilk = products.firstWhere(
          (p) => p.productName.contains('Almond'),
          orElse: () => products[0],
        );
        final eggsOrBar = products.firstWhere(
          (p) => p.productName.contains('Protein') || p.productName.contains('Sourdough'),
          orElse: () => products.length > 1 ? products[1] : products[0],
        );

        await saveProduct(almondMilk);
        await saveProduct(eggsOrBar);

        final refreshed = await _client
            .from('saved_products')
            .select()
            .eq('consumer_id', uid)
            .order('saved_at', ascending: false);

        return (refreshed as List).map((e) => ConsumerSavedProduct.fromJson(e)).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Save a product to bookmarks
  static Future<bool> saveProduct(ProductModel product) async {
    final uid = _userId;
    if (uid == null) return false;

    try {
      await _client.from('saved_products').upsert({
        'consumer_id': uid,
        'product_id': product.id,
        'product_name': product.productName,
        'brand': product.brand,
        'category': product.category ?? 'Food Item',
        'quantity': product.netQuantity ?? '1 unit',
        'image_url': product.imageUrl,
        'saved_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Unsave / remove product from bookmarks
  static Future<bool> unsaveProduct(String productId) async {
    final uid = _userId;
    if (uid == null) return false;

    try {
      await _client
          .from('saved_products')
          .delete()
          .eq('consumer_id', uid)
          .eq('product_id', productId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Toggle saved status
  static Future<bool> toggleSave(ProductModel product, bool isCurrentlySaved) async {
    if (isCurrentlySaved) {
      return !(await unsaveProduct(product.id));
    } else {
      return await saveProduct(product);
    }
  }

  /// Fetch consumer complaints
  static Future<List<ConsumerComplaintModel>> fetchMyComplaints() async {
    final uid = _userId;
    if (uid == null) return [];

    try {
      final data = await _client
          .from('consumer_complaints')
          .select()
          .eq('consumer_id', uid)
          .order('created_at', ascending: false);

      if ((data as List).isNotEmpty) {
        return data.map((e) => ConsumerComplaintModel.fromJson(e)).toList();
      }

      // Seed initial demo complaints matching Stitch design
      await submitComplaint(
        productName: 'Choco Crisp Cereal 300g',
        brand: 'MegaFoods International',
        issueCategory: 'Missing Allergen Warning',
        description: 'Allergen warning font is illegible and below the Legal Metrology minimum 1.5mm specification.',
        initialStatus: 'under_review',
        customCode: '#CPL-8924',
        customDate: DateTime.now().subtract(const Duration(days: 3)),
      );

      await submitComplaint(
        productName: 'High Protein Nut Bar 50g',
        brand: 'ProActive Nutrition',
        issueCategory: 'Incorrect Nutrition Fact',
        description: 'Printed net weight symbol format is non-compliant with standard units.',
        initialStatus: 'submitted',
        customCode: '#CPL-8891',
        customDate: DateTime.now().subtract(const Duration(days: 5)),
      );

      final refreshed = await _client
          .from('consumer_complaints')
          .select()
          .eq('consumer_id', uid)
          .order('created_at', ascending: false);

      return (refreshed as List).map((e) => ConsumerComplaintModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Submit a new consumer complaint to Supabase
  static Future<ConsumerComplaintModel?> submitComplaint({
    required String productName,
    String? brand,
    required String issueCategory,
    required String description,
    String? evidenceImageUrl,
    String initialStatus = 'submitted',
    String? customCode,
    DateTime? customDate,
  }) async {
    final uid = _userId;
    if (uid == null) return null;

    final code = customCode ?? '#CPL-${1000 + Random().nextInt(9000)}';

    try {
      final data = {
        'complaint_code': code,
        'consumer_id': uid,
        'product_name': productName.trim(),
        'brand': brand?.trim() ?? 'General Brand',
        'issue_category': issueCategory.trim(),
        'description': description.trim(),
        'evidence_image_url': evidenceImageUrl,
        'status': initialStatus,
        'created_at': (customDate ?? DateTime.now()).toIso8601String(),
        'updated_at': (customDate ?? DateTime.now()).toIso8601String(),
      };

      final res = await _client
          .from('consumer_complaints')
          .insert(data)
          .select()
          .single();

      return ConsumerComplaintModel.fromJson(res);
    } catch (e) {
      return null;
    }
  }
}
