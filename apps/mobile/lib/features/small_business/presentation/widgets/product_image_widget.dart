import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ProductImageWidget extends StatelessWidget {
  const ProductImageWidget({
    super.key,
    this.imageUrl,
    this.category,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 8,
  });

  final String? imageUrl;
  final String? category;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = _buildThemedFallback();

    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      final cleanUrl = imageUrl!.trim();

      // 1. Data URL / Base64 image
      if (cleanUrl.startsWith('data:image') || cleanUrl.contains('base64,')) {
        try {
          String base64String = cleanUrl;
          if (cleanUrl.contains('base64,')) {
            base64String = cleanUrl.split('base64,').last;
          }
          base64String = base64String.replaceAll(RegExp(r'\s+'), '');
          final bytes = base64Decode(base64.normalize(base64String));
          imageWidget = Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (ctx, err, stack) => _buildThemedFallback(),
          );
        } catch (_) {
          imageWidget = _buildThemedFallback();
        }
      }
      // 2. HTTP / HTTPS Network image
      else if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
        imageWidget = Image.network(
          cleanUrl,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: width,
              height: height,
              color: AppColors.brandDeepGreen.withValues(alpha: 0.05),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.brandDeepGreen,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            (loadingProgress.expectedTotalBytes ?? 1)
                        : null,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (ctx, err, stack) => _buildThemedFallback(),
        );
      }
      // 3. Local File Path (Android / Desktop)
      else if (!kIsWeb &&
          (cleanUrl.startsWith('/') ||
              cleanUrl.startsWith('file://') ||
              cleanUrl.contains(':\\') ||
              cleanUrl.contains(':/'))) {
        try {
          final filePath = cleanUrl.replaceFirst('file://', '');
          final file = io.File(filePath);
          if (file.existsSync()) {
            imageWidget = Image.file(
              file,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (ctx, err, stack) => _buildThemedFallback(),
            );
          } else {
            imageWidget = _buildThemedFallback();
          }
        } catch (_) {
          imageWidget = _buildThemedFallback();
        }
      }
      // 4. Asset image path
      else if (cleanUrl.startsWith('assets/') || cleanUrl.startsWith('asset:')) {
        final assetPath = cleanUrl.replaceFirst('asset:', '');
        imageWidget = Image.asset(
          assetPath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (ctx, err, stack) => _buildThemedFallback(),
        );
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: imageWidget,
      ),
    );
  }

  Widget _buildThemedFallback() {
    final catLower = (category ?? '').toLowerCase();
    final IconData iconData;
    final List<Color> gradientColors;
    final Color iconColor;
    final String categoryBadge;

    if (catLower.contains('pickle') || catLower.contains('condiment')) {
      iconData = Icons.takeout_dining_rounded;
      gradientColors = const [Color(0xFFFFF3E0), Color(0xFFFFE0B2)];
      iconColor = const Color(0xFFE65100);
      categoryBadge = 'PICKLE';
    } else if (catLower.contains('spice') ||
        catLower.contains('masala') ||
        catLower.contains('seasoning')) {
      iconData = Icons.soup_kitchen_rounded;
      gradientColors = const [Color(0xFFFFEBEE), Color(0xFFFFCDD2)];
      iconColor = const Color(0xFFC62828);
      categoryBadge = 'SPICE';
    } else if (catLower.contains('honey') || catLower.contains('sweet')) {
      iconData = Icons.eco_rounded;
      gradientColors = const [Color(0xFFFFF8E1), Color(0xFFFFECB3)];
      iconColor = const Color(0xFFF57F17);
      categoryBadge = 'HONEY';
    } else if (catLower.contains('dairy') || catLower.contains('ghee')) {
      iconData = Icons.local_drink_rounded;
      gradientColors = const [Color(0xFFE8F5E9), Color(0xFFC8E6C9)];
      iconColor = const Color(0xFF2E7D32);
      categoryBadge = 'DAIRY';
    } else if (catLower.contains('oil')) {
      iconData = Icons.opacity_rounded;
      gradientColors = const [Color(0xFFFFFDE7), Color(0xFFFFF9C4)];
      iconColor = const Color(0xFFFBC02D);
      categoryBadge = 'OIL';
    } else if (catLower.contains('snack') ||
        catLower.contains('namkeen') ||
        catLower.contains('chip')) {
      iconData = Icons.cookie_rounded;
      gradientColors = const [Color(0xFFEDE7F6), Color(0xFFD1C4E9)];
      iconColor = const Color(0xFF512DA8);
      categoryBadge = 'SNACK';
    } else if (catLower.contains('grain') ||
        catLower.contains('flour') ||
        catLower.contains('pulse')) {
      iconData = Icons.grain_rounded;
      gradientColors = const [Color(0xFFEFEBE9), Color(0xFFD7CCC8)];
      iconColor = const Color(0xFF4E342E);
      categoryBadge = 'GRAIN';
    } else if (catLower.contains('beverage') ||
        catLower.contains('tea') ||
        catLower.contains('coffee')) {
      iconData = Icons.coffee_rounded;
      gradientColors = const [Color(0xFFE0F2F1), Color(0xFFB2DFDB)];
      iconColor = const Color(0xFF00695C);
      categoryBadge = 'BEVERAGE';
    } else if (catLower.contains('bakery')) {
      iconData = Icons.bakery_dining_rounded;
      gradientColors = const [Color(0xFFFBE9E7), Color(0xFFFFCCBC)];
      iconColor = const Color(0xFFD84315);
      categoryBadge = 'BAKERY';
    } else {
      iconData = Icons.inventory_2_rounded;
      gradientColors = [
        AppColors.brandDeepGreen.withValues(alpha: 0.1),
        AppColors.brandDeepGreen.withValues(alpha: 0.18),
      ];
      iconColor = AppColors.brandDeepGreen;
      categoryBadge = 'FOOD';
    }

    final isCompact = width != null && width! < 60;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              size: isCompact ? 22 : 32,
              color: iconColor,
            ),
            if (!isCompact && height != null && height! >= 80) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  categoryBadge,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
