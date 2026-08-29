import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/business_hero_card.dart';
import '../widgets/business_info_card.dart';
import '../widgets/consumer_care_card.dart';
import '../widgets/manufacturer_details_card.dart';
import '../widgets/manufacturer_progress_bar.dart';
import '../widgets/nutrition_bottom_bar.dart';
import 'product_claims_screen.dart';

class ManufacturerDetailsScreen extends StatefulWidget {
  const ManufacturerDetailsScreen({super.key});

  @override
  State<ManufacturerDetailsScreen> createState() =>
      _ManufacturerDetailsScreenState();
}

class _ManufacturerDetailsScreenState extends State<ManufacturerDetailsScreen> {
  final TextEditingController _businessNameController = TextEditingController(
    text: 'Desi Harvest',
  );
  final TextEditingController _addressController = TextEditingController(
    text: '12, Greenfield Organic Estate, Phase 3, Pune, MH, 411028',
  );
  final TextEditingController _fssaiController = TextEditingController(
    text: '12345678901234',
  );
  final TextEditingController _marketedByController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(
    text: '+91 98765 43210',
  );
  final TextEditingController _emailController = TextEditingController(
    text: 'care@desiharvest.in',
  );
  final TextEditingController _websiteController = TextEditingController(
    text: 'www.desiharvest.in',
  );

  bool _packerAddressSameAsManufacturer = true;
  String _countryOfOrigin = 'India';

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _fssaiController.dispose();
    _marketedByController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _onNext() {
    final businessName = _businessNameController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (businessName.isEmpty ||
        address.isEmpty ||
        phone.isEmpty ||
        email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields (*)'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductClaimsScreen(
          brandName: 'Desi Harvest',
          productName: 'Authentic Mango Pickle',
          productCategory: 'Pickles & Condiments',
          netQuantity: '250 g',
          mrp: '₹ 149.00',
        ),
      ),
    );
  }

  void _onSkip() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProductClaimsScreen(),
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
                      const SizedBox(width: 4),
                      // App Icon Logo and Title
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.brandDeepGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'P',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'LabelStudio',
                          style: TextStyle(
                            color: AppColors.brandDeepGreen,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      // Notification Bell
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: AppColors.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
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
            // Step Progress Bar
            const ManufacturerProgressBar(
              currentStep: 4,
              totalSteps: 6,
              stepTitle: 'Manufacturer Details',
            ),
            const SizedBox(height: 16),

            // Hero Card: Business & Manufacturer
            const BusinessHeroCard(),
            const SizedBox(height: 16),

            // Card 1: Manufacturer Details
            ManufacturerDetailsCard(
              nameController: _businessNameController,
              addressController: _addressController,
              packerAddressSameAsManufacturer: _packerAddressSameAsManufacturer,
              onPackerSameChanged: (value) {
                if (value != null) {
                  setState(() => _packerAddressSameAsManufacturer = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Card 2: Business Information
            BusinessInfoCard(
              fssaiController: _fssaiController,
              marketedByController: _marketedByController,
              countryOfOrigin: _countryOfOrigin,
              onCountryChanged: (value) {
                if (value != null) {
                  setState(() => _countryOfOrigin = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Card 3: Consumer Care Details
            ConsumerCareCard(
              phoneController: _phoneController,
              emailController: _emailController,
              websiteController: _websiteController,
            ),
            const SizedBox(height: 100), // Bottom bar padding
          ],
        ),
      ),
      bottomNavigationBar: NutritionBottomBar(
        onBack: () => Navigator.of(context).maybePop(),
        onSkip: _onSkip,
        onNext: _onNext,
      ),
    );
  }
}
