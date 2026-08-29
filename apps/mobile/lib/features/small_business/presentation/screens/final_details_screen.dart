import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/dates_batch_pricing_card.dart';
import '../widgets/final_details_bottom_bar.dart';
import '../widgets/final_details_hero_card.dart';
import '../widgets/final_details_progress_bar.dart';
import '../widgets/packaging_environmental_card.dart';
import '../widgets/storage_usage_card.dart';
import 'product_claims_screen.dart';

class FinalDetailsScreen extends StatefulWidget {
  const FinalDetailsScreen({
    super.key,
    this.brandName = 'Desi Harvest',
    this.productName = 'Authentic Mango Pickle',
    this.productCategory = 'Pickles & Condiments',
    this.netQuantity = '250 g',
    this.mrp = '149.00',
  });

  final String brandName;
  final String productName;
  final String productCategory;
  final String netQuantity;
  final String mrp;

  @override
  State<FinalDetailsScreen> createState() => _FinalDetailsScreenState();
}

class _FinalDetailsScreenState extends State<FinalDetailsScreen> {
  // Pricing & Batch controllers
  late final TextEditingController _mrpController;
  late final TextEditingController _uspController;
  late final TextEditingController _batchController;
  late final TextEditingController _mfgDateController;
  String _selectedBestBefore = '12 Months from Packaging';

  // Storage & Usage controllers
  late final TextEditingController _storageController;
  late final TextEditingController _usageController;
  final List<String> _selectedStorageChips = [
    'Store in a cool & dry place',
    'Keep away from direct sunlight',
  ];

  // Packaging & Environmental
  String _selectedPackagingType = 'Food Grade Glass Jar';
  bool _isVegetarian = true;
  String _selectedRecyclingMark = 'Keep Clean (MoEFCC Disposal Logo)';

  @override
  void initState() {
    super.initState();
    _mrpController = TextEditingController(text: widget.mrp.replaceAll('₹', '').trim());
    _uspController = TextEditingController(text: '₹ 0.60 / g');
    _batchController = TextEditingController(text: 'DH-2026-B8');
    _mfgDateController = TextEditingController(text: 'AUG 2026');
    _storageController = TextEditingController(
      text: 'Store in a cool, dry place away from direct sunlight. Refrigerate after opening.',
    );
    _usageController = TextEditingController(
      text: 'Use a clean, dry spoon. Consume within 30 days after opening.',
    );
  }

  @override
  void dispose() {
    _mrpController.dispose();
    _uspController.dispose();
    _batchController.dispose();
    _mfgDateController.dispose();
    _storageController.dispose();
    _usageController.dispose();
    super.dispose();
  }

  void _autoCalculateUSP() {
    final mrpVal = double.tryParse(_mrpController.text.trim());
    if (mrpVal != null && mrpVal > 0) {
      // Assuming 250g as base net quantity
      final usp = mrpVal / 250.0;
      setState(() {
        _uspController.text = '₹ ${usp.toStringAsFixed(2)} / g';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calculated Unit Sale Price: ₹ ${usp.toStringAsFixed(2)} / g'),
          backgroundColor: AppColors.brandDeepGreen,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid MRP to calculate USP'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _generateBatchCode() {
    final now = DateTime.now();
    final year = now.year.toString();
    final monthChar = String.fromCharCode(65 + (now.month - 1)); // A-L
    final randomNum = (now.millisecondsSinceEpoch % 90 + 10).toString();
    final newBatch = 'DH-$year-$monthChar$randomNum';

    setState(() {
      _batchController.text = newBatch;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generated Batch Code: $newBatch'),
        backgroundColor: AppColors.brandDeepGreen,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleStorageChip(String chip) {
    setState(() {
      if (_selectedStorageChips.contains(chip)) {
        _selectedStorageChips.remove(chip);
      } else {
        _selectedStorageChips.add(chip);
      }
      _storageController.text = '${_selectedStorageChips.join('. ')}.';
    });
  }

  void _saveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Finishing details draft saved successfully'),
        backgroundColor: AppColors.brandDeepGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onContinue() {
    final mrpText = _mrpController.text.trim();
    if (mrpText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Maximum Retail Price (MRP)'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final formattedMrp = mrpText.startsWith('₹') ? mrpText : '₹ $mrpText';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductClaimsScreen(
          brandName: widget.brandName,
          productName: widget.productName,
          productCategory: widget.productCategory,
          netQuantity: widget.netQuantity,
          mrp: formattedMrp,
        ),
      ),
    );
  }

  void _onSkip() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductClaimsScreen(
          brandName: widget.brandName,
          productName: widget.productName,
          productCategory: widget.productCategory,
          netQuantity: widget.netQuantity,
          mrp: widget.mrp.startsWith('₹') ? widget.mrp : '₹ ${widget.mrp}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      // Back Button
                      Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () => Navigator.of(context).maybePop(),
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.arrow_back,
                              color: AppColors.brandDeepGreen,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Finishing Details',
                              style: TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Pricing, batch, dates & storage instructions',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Save Draft Button
                      OutlinedButton(
                        onPressed: _saveDraft,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 0),
                          side: const BorderSide(
                            color: AppColors.outlineVariant,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          foregroundColor: AppColors.onSurface,
                        ),
                        child: const Text(
                          'Save draft',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background ambient glowing blobs
          Positioned(
            top: 60,
            left: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandDeepGreen.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF005AC2).withValues(alpha: 0.04),
              ),
            ),
          ),

          // Scrollable Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Bar (Step 5 of 7, 72%)
                const FinalDetailsProgressBar(
                  currentStep: 5,
                  totalSteps: 7,
                  stepTitle: 'Finishing Details',
                  percentage: 72,
                ),
                const SizedBox(height: 16),

                // Hero Card ("Finishing Details")
                const FinalDetailsHeroCard(),
                const SizedBox(height: 16),

                // Card 1: Pricing, Batch Code & Dates
                DatesBatchPricingCard(
                  mrpController: _mrpController,
                  uspController: _uspController,
                  batchController: _batchController,
                  mfgDateController: _mfgDateController,
                  selectedBestBefore: _selectedBestBefore,
                  onBestBeforeChanged: (val) =>
                      setState(() => _selectedBestBefore = val),
                  onAutoCalculateUSP: _autoCalculateUSP,
                  onGenerateBatchCode: _generateBatchCode,
                ),
                const SizedBox(height: 16),

                // Card 2: Storage & Usage Instructions
                StorageUsageCard(
                  storageController: _storageController,
                  usageController: _usageController,
                  selectedStorageChips: _selectedStorageChips,
                  onToggleStorageChip: _toggleStorageChip,
                ),
                const SizedBox(height: 16),

                // Card 3: Packaging Material & Environmental Symbols
                PackagingEnvironmentalCard(
                  selectedPackagingType: _selectedPackagingType,
                  onPackagingTypeChanged: (val) =>
                      setState(() => _selectedPackagingType = val),
                  isVegetarian: _isVegetarian,
                  onVegetarianChanged: (val) =>
                      setState(() => _isVegetarian = val),
                  selectedRecyclingMark: _selectedRecyclingMark,
                  onRecyclingMarkChanged: (val) =>
                      setState(() => _selectedRecyclingMark = val),
                ),
                const SizedBox(height: 100), // Spacing for bottom bar
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: FinalDetailsBottomBar(
        onBack: () => Navigator.of(context).maybePop(),
        onSkip: _onSkip,
        onContinue: _onContinue,
      ),
    );
  }
}
