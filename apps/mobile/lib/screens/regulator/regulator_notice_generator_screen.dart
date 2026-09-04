import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/regulator_notice.dart';
import '../../core/services/regulator_data_service.dart';
import '../../widgets/regulator/regulator_top_app_bar.dart';

class RegulatorNoticeGeneratorScreen extends StatefulWidget {
  final String violationId;

  const RegulatorNoticeGeneratorScreen({
    super.key,
    required this.violationId,
  });

  @override
  State<RegulatorNoticeGeneratorScreen> createState() =>
      _RegulatorNoticeGeneratorScreenState();
}

class _RegulatorNoticeGeneratorScreenState
    extends State<RegulatorNoticeGeneratorScreen> {
  RegulatorNotice? _notice;
  bool _isLoading = true;
  bool _isIssuing = false;

  late TextEditingController _deadlineController;
  late TextEditingController _commentsController;
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 15));

  @override
  void initState() {
    super.initState();
    _deadlineController = TextEditingController();
    _commentsController = TextEditingController();
    _fetchDraft();
  }

  @override
  void dispose() {
    _deadlineController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _fetchDraft() async {
    setState(() => _isLoading = true);
    final draft =
        await RegulatorDataService.generateNoticeDraft(widget.violationId);
    if (mounted) {
      setState(() {
        _notice = draft;
        _selectedDeadline = draft.deadlineDate;
        _deadlineController.text =
            DateFormat('yyyy-MM-dd').format(draft.deadlineDate);
        _commentsController.text = draft.officerNotes;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDeadlineDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
        _deadlineController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _handleIssueNotice() async {
    if (_notice == null || _isIssuing) return;
    setState(() => _isIssuing = true);

    final updatedNotice = _notice!.copyWith(
      deadlineDate: _selectedDeadline,
      officerNotes: _commentsController.text,
      status: 'Issued',
    );

    await RegulatorDataService.issueNotice(updatedNotice);
    if (!mounted) return;
    setState(() => _isIssuing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Formal Notice ${updatedNotice.noticeNumber} successfully issued and dispatched.',
        ),
        backgroundColor: AppColors.primary,
      ),
    );

    Navigator.of(context).pop();
  }

  void _showFullDocumentDialog(RegulatorNotice notice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        title: Row(
          children: [
            const Icon(Icons.gavel_rounded, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Statutory Notice Preview',
              style: AppTypography.headlineSm.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GOVERNMENT OF INDIA\nDEPARTMENT OF CONSUMER AFFAIRS\nLEGAL METROLOGY DIVISION',
                textAlign: TextAlign.center,
                style: AppTypography.labelSm.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const Divider(height: 24),
              Text(
                'Notice No: ${notice.noticeNumber}',
                style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w700),
              ),
              Text('Date: ${DateFormat('dd MMMM yyyy').format(notice.issueDate)}'),
              const SizedBox(height: 8),
              Text('To,\n${notice.companyName}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Text(
                'SUBJECT: SHOW CAUSE NOTICE UNDER RULE 6 OF LEGAL METROLOGY (PACKAGED COMMODITIES) RULES, 2011.',
                style: AppTypography.labelSm.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Whereas an inspection was conducted for product "${notice.productName}", during which the following statutory violation was observed:\n\n'
                '• Violation: ${notice.ruleViolated}\n'
                '• Statute Citation: ${notice.ruleCitation}\n\n'
                'You are hereby directed to show cause in writing within 15 days (${DateFormat('dd/MM/yyyy').format(_selectedDeadline)}) as to why compounding or prosecution proceedings should not be initiated.',
                style: AppTypography.bodySm.copyWith(height: 1.4),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  notice.officerName,
                  style: AppTypography.labelSm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        appBar: RegulatorTopAppBar(
          customTitle: 'Notice Draft',
          showBackButton: true,
          showNotifications: false,
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final notice = _notice!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const RegulatorTopAppBar(
        customTitle: 'Notice Draft',
        showBackButton: true,
        showNotifications: false,
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: ClipRect(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gutter,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Document Preview Card
                _buildDocumentPreviewCard(notice),
                const SizedBox(height: AppSpacing.lg),

                // Entity History Log
                _buildEntityHistory(notice),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildStickyActionButton(),
    );
  }

  Widget _buildDocumentPreviewCard(RegulatorNotice notice) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusMd),
              ),
              border: Border(
                bottom: BorderSide(color: AppColors.surfaceVariant),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.description_rounded,
                      size: 18,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Show-Cause Notice (${notice.noticeNumber})',
                      style: AppTypography.labelMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    'Draft',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Faux Document Graphic with View Full Document overlay
          Container(
            height: 180,
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: const Color(0xFFFAFAFA),
            child: Stack(
              children: [
                // Faux document lines
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 220,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 160,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),

                // Button to view full formatted notice
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _showFullDocumentDialog(notice),
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: const Text('View Full Document'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Editable Form fields
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Response Deadline',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDeadlineDate,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                  child: IgnorePointer(
                    child: TextField(
                      controller: _deadlineController,
                      decoration: InputDecoration(
                        suffixIcon: const Icon(Icons.calendar_today_rounded,
                            size: 18, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.surfaceContainerLow,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusDefault),
                          borderSide:
                              BorderSide(color: AppColors.outlineVariant),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Additional Officer Comments / Specific Clauses',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _commentsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add specific clauses or inspection notes...',
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusDefault),
                      borderSide: BorderSide(color: AppColors.outlineVariant),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntityHistory(RegulatorNotice notice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Entity History',
          style: AppTypography.headlineSm.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.surfaceVariant),
            boxShadow: AppSpacing.cardShadow,
          ),
          child: Column(
            children: [
              for (int i = 0; i < notice.history.length; i++) ...[
                _buildHistoryRow(
                  item: notice.history[i],
                  isLast: i == notice.history.length - 1,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryRow({
    required RegulatorNoticeHistoryItem item,
    required bool isLast,
  }) {
    final isViolation = item.type == 'violation';
    final dotBg = isViolation
        ? AppColors.errorContainer
        : AppColors.secondaryContainer;
    final dotColor = isViolation ? AppColors.error : AppColors.secondary;
    final dotIcon =
        isViolation ? Icons.warning_amber_rounded : Icons.fact_check_rounded;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: dotBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(dotIcon, size: 14, color: dotColor),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.surfaceVariant,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.labelMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('MMM dd, yyyy').format(item.date)} • ${item.officerName}',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyActionButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: AppColors.surfaceVariant, width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.sm + 2,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isIssuing ? null : _handleIssueNotice,
              icon: _isIssuing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _isIssuing ? 'Issuing Notice...' : 'Issue Formal Notice',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
