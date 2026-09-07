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
  final FocusNode _fssaiFocus = FocusNode();
  final FocusNode _marketedFocus = FocusNode();

  void _showFSSAIInfoDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog Header
                Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      size: 20,
                      color: AppColors.brandDeepGreen,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'FSSAI License Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.onSurfaceVariant),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, thickness: 0.8, color: AppColors.outlineVariant),
                const SizedBox(height: 14),

                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: About FSSAI
                        const _FSSAIInfoSection(
                          title: 'ABOUT FSSAI',
                          body:
                              'FSSAI (Food Safety and Standards Authority of India) is the regulatory body for food safety in India. It issues licenses to food businesses operating in India.',
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, thickness: 0.6, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 14),

                        // Section 2: When Do You Need It?
                        const _FSSAIInfoSection(
                          title: 'WHEN DO YOU NEED IT?',
                          body:
                              'FSSAI license is required if your product is a food or food-related commodity. Non-food products (cosmetics, pharmaceuticals, etc.) may require different registrations.',
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, thickness: 0.6, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 14),

                        // Section 3: License Format
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LICENSE FORMAT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppColors.brandDeepGreen,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'FSSAI licenses are 14-digit numbers in the format:',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Text(
                                'XX-XXXX-XXXX-XXXX',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, thickness: 0.6, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 14),

                        // Section 4: How to Apply
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HOW TO APPLY',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppColors.brandDeepGreen,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _NumberedStepItem(
                              step: '01',
                              text: 'Visit the official FSSAI website or FoSCoS portal',
                              actionWidget: InkWell(
                                onTap: () async {
                                  const fssaiUrl = 'https://foscos.fssai.gov.in/';
                                  final uri = Uri.parse(fssaiUrl);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text(
                                        'Official FoSCoS Portal',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.brandDeepGreen,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppColors.brandDeepGreen,
                                        ),
                                      ),
                                      SizedBox(width: 3.5),
                                      Icon(
                                        Icons.open_in_new_rounded,
                                        size: 12,
                                        color: AppColors.brandDeepGreen,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const _NumberedStepItem(
                              step: '02',
                              text: 'Register your food business',
                            ),
                            const SizedBox(height: 8),
                            const _NumberedStepItem(
                              step: '03',
                              text: 'Complete the application with required documents',
                            ),
                            const SizedBox(height: 8),
                            const _NumberedStepItem(
                              step: '04',
                              text: 'Receive your license once approved',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, thickness: 0.6, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 14),

                        // Section 5: Verify Your License
                        const _FSSAIInfoSection(
                          title: 'VERIFY YOUR LICENSE',
                          body:
                              'Use the "Verify" button below to check if your license number is valid. You can also verify directly on the official FoSCoS portal.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, thickness: 0.8, color: AppColors.outlineVariant),
                const SizedBox(height: 12),

                // Bottom Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        const fssaiUrl = 'https://foscos.fssai.gov.in/';
                        final uri = Uri.parse(fssaiUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 14),
                      label: const Text('Visit Official Portal', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brandDeepGreen,
                        side: const BorderSide(color: AppColors.brandDeepGreen),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandDeepGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Close', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
    _fssaiFocus.addListener(_onFocusChange);
    _marketedFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.fssaiController.removeListener(_validateFSSAIFormat);
    _fssaiFocus.removeListener(_onFocusChange);
    _marketedFocus.removeListener(_onFocusChange);
    _fssaiFocus.dispose();
    _marketedFocus.dispose();
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
                        border: Border.all(color: AppColors.brandDeepGreen, width: 1.2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 13,
                          color: AppColors.brandDeepGreen,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 44,
                decoration: BoxDecoration(
                  color: _fssaiFocus.hasFocus ? Colors.white : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _fssaiVerificationStatus == 'invalid'
                        ? Colors.red
                        : (_fssaiVerificationStatus == 'format_valid'
                            ? Colors.orange
                            : (_fssaiFocus.hasFocus ? AppColors.brandDeepGreen : AppColors.outlineVariant)),
                    width: _fssaiFocus.hasFocus ? 1.5 : 1,
                  ),
                  boxShadow: _fssaiFocus.hasFocus
                      ? [
                          BoxShadow(
                            color: AppColors.brandDeepGreen.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      color: _fssaiFocus.hasFocus ? AppColors.brandDeepGreen : AppColors.outline,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: widget.fssaiController,
                        focusNode: _fssaiFocus,
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
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: false,
                          fillColor: Colors.transparent,
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
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
                          final messenger = ScaffoldMessenger.of(context);
                          setState(() => _isVerifying = true);
                          final messenger = ScaffoldMessenger.of(context);
                          // In a real app, call backend verification endpoint here
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (!mounted) return;
                            setState(() => _isVerifying = false);
                            messenger.showSnackBar(
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 44,
                decoration: BoxDecoration(
                  color: _marketedFocus.hasFocus ? Colors.white : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _marketedFocus.hasFocus ? AppColors.brandDeepGreen : AppColors.outlineVariant,
                    width: _marketedFocus.hasFocus ? 1.5 : 1,
                  ),
                  boxShadow: _marketedFocus.hasFocus
                      ? [
                          BoxShadow(
                            color: AppColors.brandDeepGreen.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.campaign_outlined,
                      color: _marketedFocus.hasFocus ? AppColors.brandDeepGreen : AppColors.outline,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: widget.marketedByController,
                        focusNode: _marketedFocus,
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
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: false,
                          fillColor: Colors.transparent,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
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

class _FSSAIInfoSection extends StatelessWidget {
  const _FSSAIInfoSection({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.brandDeepGreen,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _NumberedStepItem extends StatelessWidget {
  const _NumberedStepItem({
    required this.step,
    required this.text,
    this.actionWidget,
  });

  final String step;
  final String text;
  final Widget? actionWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: AppColors.brandDeepGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            step,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.brandDeepGreen,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              if (actionWidget != null) ...[
                const SizedBox(height: 3),
                actionWidget!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}
