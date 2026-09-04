import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import 'regulator_home_screen.dart';
import 'regulator_audit_intake_screen.dart';
import 'regulator_violation_review_screen.dart';
import 'regulator_complaint_inbox_screen.dart';
import 'regulator_complaint_detail_screen.dart';
import 'regulator_notice_generator_screen.dart';
import 'regulator_company_tracking_screen.dart';

/// RegulatorDemoEntry provides a standalone testing hub to directly launch
/// and test each of the 7 Regulator module screens.
class RegulatorDemoEntry extends StatelessWidget {
  const RegulatorDemoEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Regulator Module Demo Hub',
          style: AppTypography.headlineSm.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.primaryContainer.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fact_check_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EnforceMetrology Inspector Suite',
                          style: AppTypography.labelMd.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Test all 7 regulator screens with 8-12+ mock records and live PCR 2011 compliance flows.',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(
              'Select Screen to Launch',
              style: AppTypography.headlineSm.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            _buildScreenCard(
              context: context,
              screenNumber: 1,
              title: 'Officer Home Overview',
              subtitle: 'Dashboard with dynamic metrics, filters & priority queue of 10+ violations.',
              icon: Icons.dashboard_rounded,
              color: AppColors.primary,
              targetBuilder: () => const RegulatorHomeScreen(),
            ),
            const SizedBox(height: AppSpacing.sm),

            _buildScreenCard(
              context: context,
              screenNumber: 2,
              title: 'Scan / Audit Intake',
              subtitle: 'Photo capture, URL batch ingestion & animated 4-stage pipeline stepper.',
              icon: Icons.camera_alt_rounded,
              color: AppColors.tertiary,
              targetBuilder: () => const RegulatorAuditIntakeScreen(),
            ),
            const SizedBox(height: AppSpacing.sm),

            _buildScreenCard(
              context: context,
              screenNumber: 3,
              title: 'Violation Review',
              subtitle: 'Inspection image bounding boxes, 7 extracted declarations & action bar.',
              icon: Icons.gavel_rounded,
              color: AppColors.error,
              targetBuilder: () =>
                  const RegulatorViolationReviewScreen(violationId: 'viol-001'),
            ),
            const SizedBox(height: AppSpacing.sm),

            _buildScreenCard(
              context: context,
              screenNumber: 4,
              title: 'Consumer Complaint Inbox',
              subtitle: 'Status tabs with 8+ varied complaints, priority badges & evidence thumbnails.',
              icon: Icons.inbox_rounded,
              color: AppColors.secondary,
              targetBuilder: () => const RegulatorComplaintInboxScreen(),
            ),
            const SizedBox(height: AppSpacing.sm),

            _buildScreenCard(
              context: context,
              screenNumber: 5,
              title: 'Complaint Details View',
              subtitle: 'Full evidence gallery, consumer quote, location card & verify/reject actions.',
              icon: Icons.rate_review_rounded,
              color: AppColors.primary,
              targetBuilder: () =>
                  const RegulatorComplaintDetailScreen(complaintId: 'cmp-001'),
            ),
            const SizedBox(height: AppSpacing.sm),

            _buildScreenCard(
              context: context,
              screenNumber: 6,
              title: 'Notice & Action Generator',
              subtitle: 'Bento preview, editable deadline & comments, company entity history.',
              icon: Icons.description_rounded,
              color: AppColors.tertiary,
              targetBuilder: () =>
                  const RegulatorNoticeGeneratorScreen(violationId: 'viol-001'),
            ),
            const SizedBox(height: AppSpacing.sm),

            _buildScreenCard(
              context: context,
              screenNumber: 7,
              title: 'Company & Case Tracking',
              subtitle: 'Searchable directory with compliance scores and 5-stage vertical timelines.',
              icon: Icons.business_rounded,
              color: AppColors.primary,
              targetBuilder: () => const RegulatorCompanyTrackingScreen(),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildScreenCard({
    required BuildContext context,
    required int screenNumber,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget Function() targetBuilder,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => targetBuilder()),
        );
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.surfaceVariant),
          boxShadow: AppSpacing.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              ),
              child: Center(
                child: Icon(icon, color: color, size: 24),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          'SCREEN $screenNumber',
                          style: AppTypography.labelSm.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: AppTypography.labelMd.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.outline,
            ),
          ],
        ),
      ),
    );
  }
}
