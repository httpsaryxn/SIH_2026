import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';

class BusinessInfoCard extends StatefulWidget {
  const BusinessInfoCard({
    super.key,
    required this.fssaiController,
    required this.marketedByController,
    required this.countryOfOrigin,
    required this.onCountryChanged,
  });

  final TextEditingController fssaiController;
  final TextEditingController marketedByController;
  final String countryOfOrigin;
  final ValueChanged<String?> onCountryChanged;

  @override
  State<BusinessInfoCard> createState() => _BusinessInfoCardState();
}

class _BusinessInfoCardState extends State<BusinessInfoCard> {
  String _fssaiVerificationStatus = 'not_provided'; // not_provided, invalid, unavailable, format_valid
  bool _isVerifying = false;

  void _showFSSAIInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('FSSAI License Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '📋 What is FSSAI?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'FSSAI (Food Safety and Standards Authority of India) is the regulatory body for food safety in India. It issues licenses to food businesses operating in India.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 14),
              const Text(
                '🎯 When Do You Need It?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'FSSAI license is required if your product is a food or food-related commodity. Non-food products (cosmetics, pharmaceuticals, etc.) may require different registrations.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 14),
              const Text(
                '🔢 License Format',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'FSSAI licenses are 14-digit numbers in the format: XX-XXXX-XXXX-XXXX',
                style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 14),
              const Text(
                '🌐 How to Apply',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Visit the official FSSAI website or FoSCoS portal\n2. Register your food business\n3. Complete the application with required documents\n4. Receive your license once approved',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 14),
              const Text(
                '✓ Verify Your License',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use the "Verify" button below to check if your license number is valid. You can also verify directly on the official FoSCoS portal.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              const fssaiUrl = 'https://foscos.fssai.gov.in/';
              if (await canLaunchUrl(Uri.parse(fssaiUrl))) {
                await launchUrl(Uri.parse(fssaiUrl), mode: LaunchMode.externalApplication);
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Visit Official Portal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _validateFSSAIFormat() {
    final fssai = widget.fssaiController.text.trim();

    if (fssai.isEmpty) {
      setState(() => _fssaiVerificationStatus = 'not_provided');
      return;
    }

    // Check if it's exactly 14 digits
    if (fssai.length == 14 && fssai.split('').every((c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57)) {
      setState(() => _fssaiVerificationStatus = 'format_valid');
    } else {
      setState(() => _fssaiVerificationStatus = 'invalid');
    }
  }

  @override
  void initState() {
    super.initState();
    widget.fssaiController.addListener(_validateFSSAIFormat);
  }

  @override
  void dispose() {
    widget.fssaiController.removeListener(_validateFSSAIFormat);
    super.dispose();
  }

  Widget _buildFSSAIStatusIndicator() {
    switch (_fssaiVerificationStatus) {
      case 'invalid':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.close_rounded, color: Colors.red, size: 16),
            SizedBox(width: 4),
            Text(
              'Invalid format',
              style: TextStyle(color: Colors.red, fontSize: 11),
            ),
          ],
        );
      case 'format_valid':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.info_outlined, color: Colors.orange, size: 16),
            SizedBox(width: 4),
            Text(
              'Format valid - Verify',
              style: TextStyle(color: Colors.orange, fontSize: 11),
            ),
          ],
        );
      case 'not_provided':
      default:
        return const Text('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Document Icon
              Row(
                children: const [
                  Icon(
                    Icons.assignment_outlined,
                    color: AppColors.brandDeepGreen,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Business Information',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // FSSAI License Number Input Field with Info Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'FSSAI License Number',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showFSSAIInfoDialog,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.brandDeepGreen, width: 1.5),
                      ),
                      child: const Center(
                        child: Text(
                          'ⓘ',
                          style: TextStyle(
                            color: AppColors.brandDeepGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _fssaiVerificationStatus == 'invalid' ? Colors.red :
                           _fssaiVerificationStatus == 'format_valid' ? Colors.orange :
                           AppColors.outlineVariant,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      color: AppColors.outline,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: widget.fssaiController,
                        keyboardType: TextInputType.number,
                        maxLength: 14,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurface,
                        ),
                        decoration: const InputDecoration(
                          hintText: '14-digit license number',
                          hintStyle: TextStyle(
                            color: AppColors.outline,
                            fontSize: 13.5,
                          ),
                          border: InputBorder.none,
                          counterText: '',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // FSSAI Verification Status and Button Row
              if (widget.fssaiController.text.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFSSAIStatusIndicator(),
                    if (widget.fssaiController.text.length == 14)
                      ElevatedButton.icon(
                        onPressed: _isVerifying ? null : () {
                          // Verify button tapped
                          setState(() => _isVerifying = true);
                          // In a real app, call backend verification endpoint here
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (!mounted) return;
                            setState(() => _isVerifying = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Verification check sent. Official verification requires FSSAI portal access.'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          });
                        },
                        icon: _isVerifying
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Verify', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandDeepGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 32),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 14),

              // Marketed By Input Field
              const Text(
                'Marketed By (Optional)',
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.outlineVariant,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.campaign_outlined,
                      color: AppColors.outline,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: widget.marketedByController,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurface,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Name of marketing entity',
                          hintStyle: TextStyle(
                            color: AppColors.outline,
                            fontSize: 13.5,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Country of Origin Dropdown Field
              const Text(
                'Country of Origin',
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.public_outlined,
                      color: AppColors.outline,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: widget.countryOfOrigin,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.expand_more_rounded,
                            color: AppColors.onSurfaceVariant,
                            size: 20,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'India', child: Text('India')),
                            DropdownMenuItem(
                              value: 'United States',
                              child: Text('United States'),
                            ),
                            DropdownMenuItem(
                              value: 'United Kingdom',
                              child: Text('United Kingdom'),
                            ),
                            DropdownMenuItem(
                              value: 'Australia',
                              child: Text('Australia'),
                            ),
                          ],
                          onChanged: widget.onCountryChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
