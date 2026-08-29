import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/add_custom_claim_card.dart';
import '../widgets/claim_item_card.dart';
import '../widgets/claims_bottom_bar.dart';
import '../widgets/claims_category_tab_bar.dart';
import '../widgets/claims_hero_card.dart';
import '../widgets/claims_progress_bar.dart';
import '../widgets/claims_regulatory_notice_card.dart';
import 'label_review_export_screen.dart';

class ProductClaimsScreen extends StatefulWidget {
  const ProductClaimsScreen({
    super.key,
    this.brandName = 'Desi Harvest',
    this.productName = 'Authentic Mango Pickle',
    this.productCategory = 'Pickles & Condiments',
    this.netQuantity = '250 g',
    this.mrp = '₹ 149.00',
  });

  final String brandName;
  final String productName;
  final String productCategory;
  final String netQuantity;
  final String mrp;

  @override
  State<ProductClaimsScreen> createState() => _ProductClaimsScreenState();
}

class _ProductClaimsScreenState extends State<ProductClaimsScreen> {
  final TextEditingController _searchController = TextEditingController();
  ClaimCategory? _selectedCategory;

  // Predefined Mock Claims categorized according to FSSAI & Legal Metrology standards
  final List<ProductClaim> _allClaims = [
    // Common Claims
    const ProductClaim(
      id: 'c1',
      title: '100% Natural',
      description: 'Contains only natural agricultural ingredients without synthetic chemicals.',
      category: ClaimCategory.common,
    ),
    const ProductClaim(
      id: 'c2',
      title: 'No Added Preservatives',
      description: 'Preserved naturally using salt, spices, and cold-pressed edible oil.',
      category: ClaimCategory.common,
    ),
    const ProductClaim(
      id: 'c3',
      title: 'No Artificial Flavours',
      description: 'Flavor derived exclusively from genuine regional aromatic spices.',
      category: ClaimCategory.common,
    ),
    const ProductClaim(
      id: 'c4',
      title: 'No Artificial Colours',
      description: 'Free from synthetic food colors, tartrazine or sunset yellow.',
      category: ClaimCategory.common,
    ),
    const ProductClaim(
      id: 'c5',
      title: 'Handcrafted / Artisanal',
      description: 'Prepared in micro-batches following heritage methods.',
      category: ClaimCategory.common,
    ),
    const ProductClaim(
      id: 'c6',
      title: 'Farm Fresh Sourced',
      description: 'Raw materials procured within 24 hours of harvest.',
      category: ClaimCategory.common,
    ),

    // Dietary & Lifestyle
    const ProductClaim(
      id: 'd1',
      title: 'Gluten-Free',
      description: 'Manufactured and tested to contain less than 20 mg/kg gluten.',
      category: ClaimCategory.dietary,
      requiresLabReport: true,
      legalReference: 'FSSAI Gluten-Free Standard',
    ),
    const ProductClaim(
      id: 'd2',
      title: '100% Vegan',
      description: 'Zero animal ingredients, animal derivatives, or milk solids.',
      category: ClaimCategory.dietary,
    ),
    const ProductClaim(
      id: 'd3',
      title: 'Pure Vegetarian (Green Dot)',
      description: 'Meets mandatory Indian food safety green dot declaration.',
      category: ClaimCategory.dietary,
    ),
    const ProductClaim(
      id: 'd4',
      title: 'Zero Trans Fat',
      description: 'Contains less than 0.2g trans fat per 100g serving.',
      category: ClaimCategory.dietary,
      requiresLabReport: true,
    ),
    const ProductClaim(
      id: 'd5',
      title: 'Cholesterol-Free',
      description: 'Contains less than 5 mg cholesterol per 100g product.',
      category: ClaimCategory.dietary,
      requiresLabReport: true,
    ),
    const ProductClaim(
      id: 'd6',
      title: 'Non-GMO',
      description: 'Certified non-genetically modified crop ingredients.',
      category: ClaimCategory.dietary,
    ),

    // Nutritional & Health
    const ProductClaim(
      id: 'n1',
      title: 'High Dietary Fiber',
      description: 'Provides at least 6g of dietary fiber per 100g.',
      category: ClaimCategory.nutritional,
      requiresLabReport: true,
    ),
    const ProductClaim(
      id: 'n2',
      title: 'Low Sodium',
      description: 'Contains less than 120 mg sodium per 100g.',
      category: ClaimCategory.nutritional,
      requiresLabReport: true,
    ),
    const ProductClaim(
      id: 'n3',
      title: 'Zero Added Sugar',
      description: 'No sucrose, corn syrup, or concentrated fruit sugars added.',
      category: ClaimCategory.nutritional,
    ),
    const ProductClaim(
      id: 'n4',
      title: 'High Protein',
      description: 'Contains at least 12g protein per 100g food.',
      category: ClaimCategory.nutritional,
      requiresLabReport: true,
    ),

    // Quality & Origin
    const ProductClaim(
      id: 'q1',
      title: 'Cold Pressed Edible Oil',
      description: 'Vegetable oil extracted at room temperature via expeller.',
      category: ClaimCategory.quality,
    ),
    const ProductClaim(
      id: 'q2',
      title: 'Single Origin Sourced',
      description: 'Raw commodities grown in a single geographical GI cluster.',
      category: ClaimCategory.quality,
    ),
    const ProductClaim(
      id: 'q3',
      title: 'Traditional Indian Recipe',
      description: 'Authentic regional recipe tested for generational longevity.',
      category: ClaimCategory.quality,
    ),
    const ProductClaim(
      id: 'q4',
      title: 'Stone Ground Spices',
      description: 'Slow ground on stone mills preserving essential natural oils.',
      category: ClaimCategory.quality,
    ),
  ];

  // Selected Claims state (initialized with 3 popular compliant defaults)
  late final Set<String> _selectedClaimIds;

  @override
  void initState() {
    super.initState();
    _selectedClaimIds = {'c1', 'c2', 'q3'}; // 100% Natural, No Preservatives, Traditional Recipe
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleClaim(String id) {
    setState(() {
      if (_selectedClaimIds.contains(id)) {
        _selectedClaimIds.remove(id);
      } else {
        _selectedClaimIds.add(id);
      }
    });
  }

  void _addCustomClaim(ProductClaim newClaim) {
    setState(() {
      _allClaims.insert(0, newClaim);
      _selectedClaimIds.add(newClaim.id);
    });
  }

  void _saveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Product claims draft saved successfully'),
        backgroundColor: AppColors.brandDeepGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onContinue() {
    final selectedClaims = _allClaims
        .where((c) => _selectedClaimIds.contains(c.id))
        .toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LabelReviewExportScreen(
          brandName: widget.brandName,
          productName: widget.productName,
          productCategory: widget.productCategory,
          netQuantity: widget.netQuantity,
          mrp: widget.mrp,
          selectedClaims: selectedClaims,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = _searchController.text.trim().toLowerCase();

    // Filter claims by category & search query
    final filteredClaims = _allClaims.where((claim) {
      final matchesCategory = _selectedCategory == null ||
          claim.category == _selectedCategory;
      final matchesSearch = searchQuery.isEmpty ||
          claim.title.toLowerCase().contains(searchQuery) ||
          claim.description.toLowerCase().contains(searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();

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
                              'Product Claims',
                              style: TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Add verifiable front-of-pack claims',
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
          // Ambient blurred glowing blobs
          Positioned(
            top: 60,
            right: -50,
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
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF005AC2).withValues(alpha: 0.04),
              ),
            ),
          ),

          // Scrollable content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Progress Bar (Step 5 of 6, 83%)
                const ClaimsProgressBar(
                  currentStep: 5,
                  totalSteps: 6,
                  stepTitle: 'Product Claims',
                  percentage: 83,
                ),
                const SizedBox(height: 16),

                // Hero Card ("Add Product Claims")
                const ClaimsHeroCard(),
                const SizedBox(height: 16),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search claims (e.g. Natural, Gluten-Free, Fiber)',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppColors.outline,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.onSurfaceVariant,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                size: 18,
                                color: AppColors.onSurfaceVariant,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Category Filter Chips
                ClaimsCategoryTabBar(
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (cat) {
                    setState(() => _selectedCategory = cat);
                  },
                ),
                const SizedBox(height: 16),

                // Claims List Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategory == null
                          ? 'Available Claims (${filteredClaims.length})'
                          : '${_selectedCategory!.label} (${filteredClaims.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      '${_selectedClaimIds.length} Selected',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandDeepGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Claims Cards
                if (filteredClaims.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          size: 40,
                          color: AppColors.outline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No claims found matching "$searchQuery"',
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredClaims.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final claim = filteredClaims[index];
                      final isSelected = _selectedClaimIds.contains(claim.id);
                      return ClaimItemCard(
                        claim: claim,
                        isSelected: isSelected,
                        onTap: () => _toggleClaim(claim.id),
                      );
                    },
                  ),
                const SizedBox(height: 16),

                // Add Custom Claim Card
                AddCustomClaimCard(
                  onAddCustomClaim: _addCustomClaim,
                ),
                const SizedBox(height: 16),

                // Regulatory Notice Callout
                ClaimsRegulatoryNoticeCard(
                  selectedCount: _selectedClaimIds.length,
                ),
                const SizedBox(height: 100), // Padding for sticky bottom bar
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: ClaimsBottomBar(
        onBack: () => Navigator.of(context).maybePop(),
        onSaveDraft: _saveDraft,
        onContinue: _onContinue,
        selectedClaimsCount: _selectedClaimIds.length,
      ),
    );
  }
}
