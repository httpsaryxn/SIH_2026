import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ConsumerCareCard extends StatefulWidget {
  const ConsumerCareCard({
    super.key,
    required this.phoneController,
    required this.emailController,
    required this.websiteController,
  });

  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController websiteController;

  @override
  State<ConsumerCareCard> createState() => _ConsumerCareCardState();
}

class _ConsumerCareCardState extends State<ConsumerCareCard> {
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _websiteFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(_onFocusChange);
    _emailFocus.addListener(_onFocusChange);
    _websiteFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _phoneFocus.removeListener(_onFocusChange);
    _emailFocus.removeListener(_onFocusChange);
    _websiteFocus.removeListener(_onFocusChange);
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _websiteFocus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
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
              // Header with Support Icon
              Row(
                children: [
                  const Icon(
                    Icons.support_agent_rounded,
                    color: AppColors.brandDeepGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Consumer Care Details',
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

              // Consumer Care Number Input Field
              const Text(
                'Consumer Care Number *',
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
                  color: _phoneFocus.hasFocus ? Colors.white : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _phoneFocus.hasFocus ? AppColors.brandDeepGreen : AppColors.outlineVariant,
                    width: _phoneFocus.hasFocus ? 1.5 : 1,
                  ),
                  boxShadow: _phoneFocus.hasFocus
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
                      Icons.phone_outlined,
                      color: _phoneFocus.hasFocus ? AppColors.brandDeepGreen : AppColors.outline,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: widget.phoneController,
                        focusNode: _phoneFocus,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurface,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter phone number',
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

              // Consumer Care Email Input Field
              const Text(
                'Consumer Care Email *',
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
                  color: _emailFocus.hasFocus ? Colors.white : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _emailFocus.hasFocus ? AppColors.brandDeepGreen : AppColors.outlineVariant,
                    width: _emailFocus.hasFocus ? 1.5 : 1,
                  ),
                  boxShadow: _emailFocus.hasFocus
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
                      Icons.email_outlined,
                      color: _emailFocus.hasFocus ? AppColors.brandDeepGreen : AppColors.outline,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: widget.emailController,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurface,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter email address',
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

              // Website Input Field
              const Text(
                'Website (Optional)',
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
                  color: _websiteFocus.hasFocus ? Colors.white : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _websiteFocus.hasFocus ? AppColors.brandDeepGreen : AppColors.outlineVariant,
                    width: _websiteFocus.hasFocus ? 1.5 : 1,
                  ),
                  boxShadow: _websiteFocus.hasFocus
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
                      Icons.language_outlined,
                      color: _websiteFocus.hasFocus ? AppColors.brandDeepGreen : AppColors.outline,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: widget.websiteController,
                        focusNode: _websiteFocus,
                        keyboardType: TextInputType.url,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurface,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'www.example.com',
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
            ],
          ),
        ),
      ),
    );
  }
}
