import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/create_label_bottom_bar.dart';
import '../widgets/declaration_hero_card.dart';
import '../widgets/label_progress_card.dart';
import '../widgets/product_basic_details_form.dart';
import '../widgets/product_category_selector.dart';
import '../widgets/trust_callout_card.dart';

import 'ingredients_allergens_screen.dart';

class CreateLabelDeclarationScreen extends StatefulWidget {
  const CreateLabelDeclarationScreen({super.key});

  @override
  State<CreateLabelDeclarationScreen> createState() =>
      _CreateLabelDeclarationScreenState();
}

class _CreateLabelDeclarationScreenState
    extends State<CreateLabelDeclarationScreen> {
  final TextEditingController _brandNameController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _typeFlavourController = TextEditingController();

  String? _selectedCategory;
  String? _uploadedLogoName;

  @override
  void dispose() {
    _brandNameController.dispose();
    _productNameController.dispose();
    _typeFlavourController.dispose();
    super.dispose();
  }

  void _saveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft saved successfully'),
        backgroundColor: AppColors.brandDeepGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _uploadLogo() {
    setState(() {
      _uploadedLogoName = 'brand_logo_master.png';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Brand logo selected: brand_logo_master.png'),
        backgroundColor: AppColors.brandDeepGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onCategoryHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Category Guidance'),
        content: const Text(
          'Product categories determine specific Legal Metrology and packaging declaration standards for your label. Select the category that best matches your primary commodity.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _onContinue() {
    final brand = _brandNameController.text.trim();
    final product = _productNameController.text.trim();

    if (brand.isEmpty || product.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least Brand Name and Product Name.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const IngredientsAllergensScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
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
                              color: AppColors.onSurface,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Title and Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Create Label',
                              style: TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              'Product information',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 12,
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator (Step 1 of 6, 17%)
            const LabelProgressCard(
              currentStep: 1,
              totalSteps: 6,
              stepTitle: 'Declaration',
              percentage: 17,
            ),
            const SizedBox(height: 20),

            // Hero Section ("Tell us about your product")
            const DeclarationHeroCard(),
            const SizedBox(height: 20),

            // Product Category Selector
            ProductCategorySelector(
              selectedCategory: _selectedCategory,
              onCategoryChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              onHelpTap: _onCategoryHelp,
            ),
            const SizedBox(height: 20),

            // Product Details Form
            ProductBasicDetailsForm(
              brandNameController: _brandNameController,
              productNameController: _productNameController,
              typeFlavourController: _typeFlavourController,
              uploadedLogoName: _uploadedLogoName,
              onUploadLogoTap: _uploadLogo,
            ),
            const SizedBox(height: 20),

            // Trust Callout Card
            const TrustCalloutCard(),
            const SizedBox(height: 100), // Spacing for sticky bottom bar
          ],
        ),
      ),
      bottomNavigationBar: CreateLabelBottomBar(
        onBack: () => Navigator.of(context).maybePop(),
        onSaveDraft: _saveDraft,
        onContinue: _onContinue,
      ),
    );
  }
}
