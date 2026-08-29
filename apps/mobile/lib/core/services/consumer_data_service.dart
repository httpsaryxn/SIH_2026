import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/consumer_complaint_model.dart';
import '../models/consumer_notification_model.dart';
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

  /// Fetch recent scans for current consumer
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
          (p) => p.productName.contains('Sourdough') || p.productName.contains('Bread'),
          orElse: () => products[0],
        );
        final choco = products.firstWhere(
          (p) => p.productName.contains('Choco') || p.productName.contains('Crisp'),
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
          'manufacturer_address': product.manufacturerAddress,
          'mrp': product.mrp,
          'fssai_license_no': product.fssaiLicenseNo,
          'mfg_date': product.mfgDate,
          'best_before': product.bestBefore,
          'consumer_care_info': product.consumerCareInfo,
        },
        'scan_notes': product.complianceIssues.isNotEmpty
            ? product.complianceIssues.first['message']
            : 'All mandatory Legal Metrology declarations verified. No obvious issue detected.',
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

  /// Delete a scan
  static Future<bool> deleteScan(String scanId) async {
    final uid = _userId;
    if (uid == null) return false;

    try {
      await _client
          .from('consumer_scans')
          .delete()
          .eq('consumer_id', uid)
          .eq('id', scanId);
      return true;
    } catch (e) {
      return false;
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
        final proteinBar = products.firstWhere(
          (p) => p.productName.contains('Protein') || p.productName.contains('Sourdough'),
          orElse: () => products.length > 1 ? products[1] : products[0],
        );

        await saveProduct(almondMilk);
        await saveProduct(proteinBar);

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

      // Seed initial demo complaints matching requirements
      await submitComplaint(
        productName: 'ABC Snacks & Confectionery',
        brand: 'XYZ Foods Pvt Ltd',
        issueCategory: 'Potential MRP Discrepancy',
        description: 'Dual MRP stickers observed on package with conflicting prices at supermarket.',
        storeLocation: 'City Center Mall, Sector 14',
        initialStatus: 'under_review',
        customCode: 'CMP-2026-001284',
        customDate: DateTime.now().subtract(const Duration(days: 2)),
      );

      await submitComplaint(
        productName: 'Choco Crisp Cereal 300g',
        brand: 'MegaFoods International',
        issueCategory: 'Missing Allergen Warning',
        description: 'Allergen warning text size is printed below mandatory 1.5mm threshold.',
        storeLocation: 'FreshMart Supermarket',
        initialStatus: 'forwarded_to_company',
        customCode: 'CMP-2026-000892',
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

  /// Submit a new consumer complaint
  static Future<ConsumerComplaintModel?> submitComplaint({
    required String productName,
    String? brand,
    required String issueCategory,
    required String description,
    String? storeLocation,
    String? evidenceImageUrl,
    String initialStatus = 'submitted',
    String? customCode,
    DateTime? customDate,
  }) async {
    final uid = _userId;
    if (uid == null) return null;

    final code = customCode ?? 'CMP-2026-${(100000 + Random().nextInt(900000))}';

    try {
      final data = {
        'complaint_code': code,
        'consumer_id': uid,
        'product_name': productName.trim(),
        'brand': brand?.trim() ?? 'General Brand',
        'issue_category': issueCategory.trim(),
        'description': description.trim(),
        'store_location': storeLocation?.trim(),
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

      // Create notification
      await _client.from('consumer_notifications').insert({
        'consumer_id': uid,
        'title': 'Complaint Submitted',
        'message': 'Your complaint $code for $productName has been logged with authorities.',
        'type': 'complaint_update',
        'related_complaint_id': res['id'],
      });

      return ConsumerComplaintModel.fromJson(res);
    } catch (e) {
      return null;
    }
  }

  /// Fetch user notifications
  static Future<List<ConsumerNotificationModel>> fetchNotifications() async {
    final uid = _userId;
    if (uid == null) return [];

    try {
      final data = await _client
          .from('consumer_notifications')
          .select()
          .eq('consumer_id', uid)
          .order('created_at', ascending: false);

      return (data as List).map((e) => ConsumerNotificationModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }
}
