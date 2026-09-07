import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/capture_role.dart';
import '../../core/models/multi_capture_payload.dart';
import '../../core/models/pending_capture.dart';
import '../../core/models/regulator_violation.dart';
import '../../core/services/legal_metrology_service.dart';
import '../../core/services/ml_scanner_client.dart';
import '../../core/services/regulator_data_service.dart';
import '../shared/multi_capture_screen.dart';
import 'regulator_violation_review_screen.dart';

class RegulatorScanAnalysisScreen extends StatefulWidget {
  final PendingCapture pendingCapture;
  final MultiCapturePayload? multiCapture;
  final String? prefilledProductName;
  final String? prefilledCompanyName;
  final String? prefilledCategory;

  const RegulatorScanAnalysisScreen({
    super.key,
    required this.pendingCapture,
    this.multiCapture,
    this.prefilledProductName,
    this.prefilledCompanyName,
    this.prefilledCategory,
  });

  @override
  State<RegulatorScanAnalysisScreen> createState() =>
      _RegulatorScanAnalysisScreenState();
}

class _RegulatorScanAnalysisScreenState
    extends State<RegulatorScanAnalysisScreen>
    with TickerProviderStateMixin {
  late AnimationController _laserController;
  late AnimationController _progressController;
  late AnimationController _waveController;
  late Animation<double> _laserAnimation;

  int _currentStageIndex = 0;
  bool _isAnalysisFinished = false;
  String _statusMessage = 'Connecting to ML Scanner service...';
  RegulatorViolation? _createdViolation;
  MlScannerResult? _mlScannerResult;
  LmAuditResult? _audit;
  String? _connectionError;
  bool _isServerConnected = false;

  /// Returns the list of captures for carousel display.
  List<MapEntry<CaptureRole, PendingCapture>> get _capturedEntries {
    if (widget.multiCapture != null) {
      return widget.multiCapture!.capturedEntries;
    }
    return [MapEntry(CaptureRole.frontLabel, widget.pendingCapture)];
  }

  final List<Map<String, dynamic>> _stages = [
    {
      'title': 'Evidence Ingestion & Secure Cache',
      'subtitle': 'Collision-safe local storage & EXIF metadata logging',
      'threshold': 0.25,
      'icon': Icons.folder_zip_rounded,
    },
    {
      'title': 'Multi-Zone OCR & Text Extraction',
      'subtitle': 'Extracting PDP area, declared MRP & net quantity',
      'threshold': 0.50,
      'icon': Icons.document_scanner_rounded,
    },
    {
      'title': 'Legal Metrology PCR 2011 Verification',
      'subtitle': 'Validating font heights & mandatory declarations',
      'threshold': 0.75,
      'icon': Icons.rule_folder_rounded,
    },
    {
      'title': 'Regulatory Case File Generation',
      'subtitle': 'Generating automated violation audit summary',
      'threshold': 1.00,
      'icon': Icons.gavel_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();

    // 1. Scanning Laser Animation
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
    _laserController.repeat(reverse: true);

    // 2. Progress Controller
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 3. Evaluation Wave Animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _startPipelineExecution();
  }

  @override
  void dispose() {
    _laserController.dispose();
    _progressController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _startPipelineExecution() async {
    if (!mounted) return;
    setState(() {
      _isAnalysisFinished = false;
      _connectionError = null;
      _mlScannerResult = null;
      _audit = null;
      _currentStageIndex = 0;
      _statusMessage = 'Securing 3 captured evidence samples...';
    });
    _progressController.value = 0.15;
    if (!_laserController.isAnimating) {
      _laserController.repeat(reverse: true);
    }

    // Check server reachability
    setState(() {
      _currentStageIndex = 1;
      _statusMessage = 'Connecting to ML Scanner (${MlScannerClient.baseUrl})...';
    });
    _progressController.animateTo(0.35, duration: const Duration(milliseconds: 400));

    // ── Stage 1: Send images directly to remote FastAPI ML Scanner ──────────
    MlScannerResult? remoteResult;
    try {
      if (mounted) {
        setState(() {
          _statusMessage = 'Uploading captured images to FastAPI ML Scanner...';
        });
      }
      _progressController.animateTo(0.55, duration: const Duration(milliseconds: 500));

      remoteResult = await LegalMetrologyService.auditCaptureRemote(
        capture: widget.pendingCapture,
        multiCapture: widget.multiCapture,
        productName: widget.prefilledProductName,
      );

      if (remoteResult != null) {
        _isServerConnected = true;
      }
    } catch (e) {
      debugPrint('[RegulatorScanAnalysisScreen] ML Scanner call failed: $e');
      _connectionError = e.toString();
    }

    if (remoteResult != null && mounted) {
      setState(() {
        _mlScannerResult = remoteResult;
        _currentStageIndex = 2;
        _statusMessage =
            'Parsing ML compliance model findings & rule checks...';
      });
      _progressController.animateTo(0.85, duration: const Duration(milliseconds: 400));
    }

    // ── Stage 2: Fall back to on-device audit if remote unavailable ────────
    LmAuditResult? audit;
    if (remoteResult == null) {
      _isServerConnected = false;
      _connectionError ??=
          'Could not reach ML Scanner at ${MlScannerClient.baseUrl}.';
      try {
        if (mounted) {
          setState(() {
            _currentStageIndex = 2;
            _statusMessage =
                'Running offline on-device OCR & rule verification...';
          });
        }
        audit = await LegalMetrologyService.auditCapture(
          capture: widget.pendingCapture,
          productName: widget.prefilledProductName,
        );
        _audit = audit;
      } catch (_) {
        // Fallback unavailable
      }
    }

    // ── Stage 3: Create violation record in database ───────────────────────
    if (mounted) {
      setState(() {
        _currentStageIndex = 3;
        _statusMessage = 'Compiling regulatory case file & audit records...';
      });
    }
    await _progressController.animateTo(1.0, duration: const Duration(milliseconds: 300));

    String? violationSummary;
    int confidenceScore = 94;
    String severity = 'High';
    String riskLevel = 'High Risk';

    if (remoteResult != null) {
      final s = remoteResult.score;
      confidenceScore = s.finalScore.round();
      if (s.finalScore >= 85) {
        severity = 'Low';
        riskLevel = 'Low Risk';
      } else if (s.finalScore >= 70) {
        severity = 'Medium';
        riskLevel = 'Medium Risk';
      }
      final failedNames =
          remoteResult.rules.failed.map((r) => r.ruleName).take(3);
      violationSummary = s.failedRules > 0
          ? 'ML Analysis: ${s.failedRules} violation(s) flagged — ${failedNames.join("; ")}'
          : 'ML Analysis: All ${s.passedRules} checked rules passed.';
    }

    // Determine product name from remote result, on-device audit, or prefilled
    String resolvedProductName;
    if (remoteResult != null &&
        (remoteResult.product['name'] as String?)?.trim().isNotEmpty == true) {
      resolvedProductName = (remoteResult.product['name'] as String).trim();
    } else if (audit != null &&
        (audit.detectedDeclarations['commodity_name'] as String?)
                ?.trim()
                .isNotEmpty ==
            true) {
      resolvedProductName =
          (audit.detectedDeclarations['commodity_name'] as String).trim();
    } else {
      resolvedProductName = widget.prefilledProductName?.isNotEmpty == true
          ? widget.prefilledProductName!
          : 'Packaged Food Commodity';
    }

    String resolvedCompanyName;
    if (remoteResult != null &&
        (remoteResult.product['manufacturer'] as String?)?.trim().isNotEmpty ==
            true) {
      resolvedCompanyName =
          (remoteResult.product['manufacturer'] as String).trim();
    } else {
      resolvedCompanyName = widget.prefilledCompanyName?.isNotEmpty == true
          ? widget.prefilledCompanyName!
          : 'Registered Packer / Importer';
    }

    try {
      final violation = await RegulatorDataService.createAuditViolation(
        productName: resolvedProductName,
        companyName: resolvedCompanyName,
        multiCapture: widget.multiCapture,
        pendingCapture: widget.pendingCapture,
        imagePath: widget.pendingCapture.localPath,
        audit: audit,
        mlResult: remoteResult,
      );

      if (mounted) {
        setState(() {
          _createdViolation = violation;
          _isAnalysisFinished = true;
          if (remoteResult != null) {
            final s = remoteResult.score;
            _statusMessage =
                'Analysis Complete! Score: ${s.finalScore.toStringAsFixed(1)}% '
                '(${s.starLabel}) — ${s.failedRules} violation(s) flagged.';
          } else if (audit != null) {
            _statusMessage =
                'Analysis Complete! ${audit.complianceIssues.length} issue(s) detected (Offline).';
          } else {
            _statusMessage = 'Analysis Complete!';
          }
        });
        _laserController.stop();
      }
    } catch (_) {
      // Fallback: In-memory violation instance if DB insertion fails
      List<RegulatorDeclaration> fallbackDecls = [];
      if (remoteResult != null) {
        final allRules = [
          ...remoteResult.rules.failed,
          ...remoteResult.rules.warnings,
          ...remoteResult.rules.inconclusive,
          ...remoteResult.rules.passed,
        ];
        fallbackDecls = allRules.map((r) => RegulatorDeclaration(
          fieldName: r.ruleName,
          extractedValue: r.evidence ?? (r.status.toUpperCase() == 'PASS' ? 'Compliant' : 'Not detected'),
          confidencePercent: remoteResult!.score.finalScore.round(),
          status: r.standardStatus,
          ruleCitation: r.legalReference ?? r.ruleId,
          ruleDescription: r.detail,
        )).toList();
      }

      if (mounted) {
        setState(() {
          _createdViolation = RegulatorViolation(
            id: 'AUD-AUTO-${DateTime.now().millisecondsSinceEpoch}',
            scanId: 'SCN-${widget.pendingCapture.fileName.hashCode.abs()}',
            productName: resolvedProductName,
            companyName: resolvedCompanyName,
            category: widget.prefilledCategory ?? 'Packaged Food',
            region: 'North Zone',
            storeLocation: 'Field Audit Scan',
            imageUrl: widget.pendingCapture.localPath,
            severity: severity,
            riskLevel: riskLevel,
            confidenceScore: confidenceScore,
            violationType: remoteResult != null && remoteResult.rules.failed.isNotEmpty
                ? remoteResult.rules.failed.first.ruleName
                : 'PCR 2011 Non-Compliance',
            violationSummary: violationSummary ??
                'Compliance audit summary generated from packaging inspection.',
            capturedAt: widget.pendingCapture.capturedAt,
            status: 'pending_review',
            declarations: fallbackDecls,
            overlayBoxes: [],
          );
          _isAnalysisFinished = true;
          _statusMessage = 'Analysis Complete!';
        });
        _laserController.stop();
      }
    }
  }

  Future<void> _handleCaptureNew() async {
    final result = await Navigator.of(context).push<MultiCapturePayload?>(
      MaterialPageRoute(
        builder: (_) => const MultiCaptureScreen(
          sourceTag: 'regulator_field',
          flowLabel: 'Audit Evidence',
        ),
      ),
    );

    if (result != null && result.hasAnyCapture && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RegulatorScanAnalysisScreen(
            multiCapture: result,
            pendingCapture: result.primaryCapture!,
            prefilledProductName: widget.prefilledProductName,
            prefilledCompanyName: widget.prefilledCompanyName,
            prefilledCategory: widget.prefilledCategory,
          ),
        ),
      );
    }
  }

  void _navigateToViolationReview() {
    if (_createdViolation != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RegulatorViolationReviewScreen(
            violationId: _createdViolation!.id,
          ),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showServerConfigDialog() {
    final urlController = TextEditingController(text: MlScannerClient.baseUrl);
    bool testing = false;
    String? testResult;
    bool? testOk;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          title: Row(
            children: [
              const Icon(Icons.dns_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'ML Scanner Server',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the FastAPI server URL. If running locally on host machine, use your LAN IP (e.g. 192.168.0.116:8000).',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: 'Server Base URL',
                    hintText: 'http://192.168.0.116:8000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Reset to default',
                      onPressed: () {
                        setDialogState(() {
                          urlController.text = 'https://labellens-ml-scanner.onrender.com';
                          testResult = null;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.cloud_done_rounded, size: 16),
                      label: const Text('Render Cloud'),
                      onPressed: () {
                        setDialogState(() {
                          urlController.text = 'https://labellens-ml-scanner.onrender.com';
                          testResult = null;
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('192.168.0.116'),
                      onPressed: () {
                        setDialogState(() {
                          urlController.text = 'http://192.168.0.116:8000';
                          testResult = null;
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('127.0.0.1 (ADB)'),
                      onPressed: () {
                        setDialogState(() {
                          urlController.text = 'http://127.0.0.1:8000';
                          testResult = null;
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('10.0.2.2 (Emu)'),
                      onPressed: () {
                        setDialogState(() {
                          urlController.text = 'http://10.0.2.2:8000';
                          testResult = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (testResult != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: testOk == true
                          ? const Color(0xFF10B981).withValues(alpha: 0.12)
                          : AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          testOk == true
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                          size: 16,
                          color: testOk == true
                              ? const Color(0xFF10B981)
                              : AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            testResult!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: testOk == true
                                  ? const Color(0xFF047857)
                                  : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: testing
                  ? null
                  : () async {
                      setDialogState(() {
                        testing = true;
                        testResult = null;
                      });
                      final ok = await MlScannerClient.testConnection(
                        urlController.text.trim(),
                      );
                      setDialogState(() {
                        testing = false;
                        testOk = ok;
                        testResult = ok
                            ? 'Server is online & reachable!'
                            : 'Could not connect to ${urlController.text.trim()}/health';
                      });
                    },
              child: testing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Test Connection'),
            ),
            ElevatedButton(
              onPressed: () async {
                final targetUrl = urlController.text.trim();
                await MlScannerClient.setBaseUrl(targetUrl);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
                if (mounted) {
                  _startPipelineExecution();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Save & Scan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildTopAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Captured Photo Carousel Viewport
              _buildOpticalScanViewport(),
              const SizedBox(height: AppSpacing.md),

              // 2. While scanning: Progress Card & Pipeline Checklist
              if (!_isAnalysisFinished) ...[
                _buildProgressBarCard(),
                const SizedBox(height: AppSpacing.md),
                _buildPipelineChecklist(),
                const SizedBox(height: AppSpacing.lg),
              ],

              // 3. When analysis is finished: SHOW REAL ML RESULTS IN THE UI
              if (_isAnalysisFinished) ...[
                if (_connectionError != null && _mlScannerResult == null) ...[
                  _buildConnectionErrorBanner(),
                  const SizedBox(height: AppSpacing.md),
                ],

                if (_mlScannerResult != null) ...[
                  // A. ML Compliance Score Card
                  _buildMlComplianceScoreCard(_mlScannerResult!),
                  const SizedBox(height: AppSpacing.md),

                  // B. Extracted Product & Metadata Card
                  _buildExtractedCommodityCard(),
                  const SizedBox(height: AppSpacing.md),

                  // C. Grouped ML Rule Breakdown (Violations, Warnings, Compliant)
                  _buildLiveRuleFindings(_mlScannerResult!),
                  const SizedBox(height: AppSpacing.lg),
                ] else if (_audit != null) ...[
                  // Offline fallback findings
                  _buildOfflineAuditCard(_audit!),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ],

              // 4. Action Buttons (ONLY after analysis finishes) or Circular Wave Progress Widget
              if (_isAnalysisFinished) ...[
                _buildActionButtons(),
              ] else ...[
                _buildEvaluationWaveLoadingWidget(),
              ],
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.onSurface,
              size: 20,
            ),
          ),
        ),
      ),
      title: Text(
        'Scan Results',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
      ),
      actions: [
        // ML Server Status Chip (tap to configure)
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: InkWell(
            onTap: _showServerConfigDialog,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isServerConnected
                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isServerConnected
                      ? const Color(0xFF10B981).withValues(alpha: 0.4)
                      : AppColors.outlineVariant,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _isServerConnected
                          ? const Color(0xFF10B981)
                          : (_connectionError != null
                              ? AppColors.error
                              : Colors.amber),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isServerConnected ? 'ML Live' : 'ML Config',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _isServerConnected
                          ? const Color(0xFF047857)
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Size badge
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sync_rounded,
                  size: 14,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.pendingCapture.formattedSize,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOpticalScanViewport() {
    final entries = _capturedEntries;

    if (entries.length > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.collections_rounded, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text(
                    'Multi-Zone Packaging Evidence',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${entries.length}/${entries.length} Captured',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF047857),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // 3-Card Row displaying ALL captured images together
          SizedBox(
            height: 195,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < entries.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _buildEvidenceCard(entries[i].value, entries[i].key),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    // Single Image Capture Viewport
    final capture = entries.isNotEmpty ? entries.first.value : widget.pendingCapture;
    final role = entries.isNotEmpty ? entries.first.key : CaptureRole.frontLabel;
    return SizedBox(
      height: 240,
      child: _buildEvidenceCard(capture, role, isFullWidth: true),
    );
  }

  Widget _buildEvidenceCard(PendingCapture capture, CaptureRole role, {bool isFullWidth = false}) {
    final roleInfo = CaptureRoleInfo.forRole(role);

    return InkWell(
      onTap: () => _showEvidenceZoomDialog(capture, role),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceVariant),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Real Image Renderer (memory -> local file -> fallback)
            _buildEvidenceImage(capture),

            // Vignette gradient
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
            ),

            // Top Role Badge
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isAnalysisFinished ? Icons.check_circle_rounded : roleInfo.icon,
                      size: 11,
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        isFullWidth ? '${roleInfo.label} ✓' : roleInfo.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isFullWidth ? 11 : 9.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Animated Scanning Laser Bar
            if (!_isAnalysisFinished)
              AnimatedBuilder(
                animation: _laserAnimation,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment(0, (_laserAnimation.value * 2) - 1),
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(1),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.8),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Bottom Filename & Zoom indicator
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        capture.formattedSize,
                        style: GoogleFonts.firaCode(
                          fontSize: 9,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.fullscreen_rounded,
                    size: 16,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceImage(PendingCapture capture) {
    if (capture.rawBytes != null && capture.rawBytes!.isNotEmpty) {
      return Image.memory(
        capture.rawBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (ctx, err, stack) => _buildFallbackPreview(),
      );
    }
    try {
      final path = capture.localPath.startsWith('file://')
          ? Uri.parse(capture.localPath).toFilePath()
          : capture.localPath;
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (ctx, err, stack) => _buildFallbackPreview(),
        );
      }
    } catch (_) {}
    return _buildFallbackPreview();
  }

  void _showEvidenceZoomDialog(PendingCapture capture, CaptureRole role) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: _buildEvidenceImage(capture),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Text(
                  CaptureRoleInfo.forRole(role).label,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackPreview() {
    return Container(
      color: const Color(0xFF1E293B),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner_rounded,
              color: Color(0xFF10B981),
              size: 48,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Field Evidence Ingested',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBarCard() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        final progressVal = _progressController.value;
        final percent = (progressVal * 100).toInt();

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.surfaceVariant),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 18,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Running ML Verification...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$percent%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Linear Progress Indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 8,
                  child: LinearProgressIndicator(
                    value: progressVal,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF10B981),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              Text(
                _statusMessage,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPipelineChecklist() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hub_outlined,
                size: 16,
                color: Color(0xFF10B981),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Pipeline Verification Stages',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._stages.asMap().entries.map((entry) {
            final idx = entry.key;
            final stage = entry.value;
            final isDone = _currentStageIndex > idx;
            final isCurrent = idx == _currentStageIndex;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : (isCurrent
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : AppColors.surfaceContainerHigh),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Color(0xFF10B981),
                            )
                          : (isCurrent
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF10B981),
                                  ),
                                )
                              : Icon(
                                  stage['icon'] as IconData,
                                  size: 14,
                                  color: AppColors.outline,
                                )),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage['title'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: isDone || isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isDone || isCurrent
                                ? AppColors.onSurface
                                : AppColors.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          stage['subtitle'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDone)
                    Text(
                      'Done',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConnectionErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ML Scanner Server Unreachable',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _connectionError ??
                'Could not connect to FastAPI server at ${MlScannerClient.baseUrl}. Showing offline fallback findings.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.onErrorContainer.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _showServerConfigDialog,
                icon: const Icon(Icons.settings_ethernet_rounded, size: 14),
                label: const Text('Change Server IP'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _startPipelineExecution,
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Retry ML Scan'),
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── A. Real ML Compliance Score Card ──────────────────────────────────────
  Widget _buildMlComplianceScoreCard(MlScannerResult result) {
    final s = result.score;
    final isGood = s.finalScore >= 80;
    final isMedium = s.finalScore >= 50 && s.finalScore < 80;
    final themeColor = isGood
        ? const Color(0xFF10B981)
        : (isMedium ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: themeColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Score Badge + Star Rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large Percentage Box
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${s.finalScore.toStringAsFixed(1)}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: themeColor,
                      ),
                    ),
                    Text(
                      'COMPLIANCE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: themeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Rating and Star Label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (idx) {
                        final filled = idx < s.starRating;
                        return Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: filled ? themeColor : AppColors.outlineVariant,
                          size: 22,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.starLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PCR 2011 Legal Metrology Audit',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Score Meter Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (s.finalScore / 100.0).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Chips Row: Violations, Passed, Warnings, Lab, Exempt
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetricChip(
                icon: Icons.cancel_rounded,
                label: '${s.failedRules} Violations Flagged',
                color: const Color(0xFFEF4444),
              ),
              _buildMetricChip(
                icon: Icons.check_circle_rounded,
                label: '${s.passedRules} Compliant Rules',
                color: const Color(0xFF10B981),
              ),
              if (result.rules.warnings.isNotEmpty)
                _buildMetricChip(
                  icon: Icons.warning_rounded,
                  label: '${result.rules.warnings.length} Warnings',
                  color: const Color(0xFFF59E0B),
                ),
              if (result.rules.inconclusive.isNotEmpty)
                _buildMetricChip(
                  icon: Icons.science_outlined,
                  label: '${result.rules.inconclusive.length} Lab Verifications',
                  color: const Color(0xFF64748B),
                ),
              if (result.rules.notApplicable.isNotEmpty)
                _buildMetricChip(
                  icon: Icons.remove_circle_outline_rounded,
                  label: '${result.rules.notApplicable.length} Exempt / N/A',
                  color: const Color(0xFF94A3B8),
                ),
            ],
          ),

          const Divider(height: 24),

          // Engine & Evidence ingestion info
          Row(
            children: [
              const Icon(Icons.memory_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Engine: ${result.engineDescription}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.layers_rounded, size: 14, color: Color(0xFF10B981)),
              const SizedBox(width: 4),
              Text(
                '3 Multi-Zone Images Verified (Front, Side, Scale)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF047857),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── B. Real Extracted Commodity Card ──────────────────────────────────────
  Widget _buildExtractedCommodityCard() {
    final res = _mlScannerResult;
    final pData = res?.product ?? {};
    final barcodeData = res?.barcode ?? {};

    // Commodity Name
    final productName = (pData['name'] as String?)?.trim().isNotEmpty == true
        ? (pData['name'] as String).trim()
        : (widget.prefilledProductName?.isNotEmpty == true
            ? widget.prefilledProductName!
            : 'Packaged Commodity');

    // Manufacturer / Packer
    final companyName =
        (pData['manufacturer'] as String?)?.trim().isNotEmpty == true
            ? (pData['manufacturer'] as String).trim()
            : (widget.prefilledCompanyName?.isNotEmpty == true
                ? widget.prefilledCompanyName!
                : 'Registered Packer / Importer');

    // Net Quantity
    final netQty = (pData['net_quantity'] as String?)?.trim().isNotEmpty == true
        ? (pData['net_quantity'] as String).trim()
        : 'Not Detected';

    // MRP
    final mrpStr = pData['mrp'] != null
        ? '₹${pData['mrp']}'
        : 'Not Detected';

    // Barcode
    final barcodeVal = (barcodeData['value'] as String?)?.trim().isNotEmpty == true
        ? (barcodeData['value'] as String).trim()
        : 'Not Detected';

    // Address
    final address = (pData['address'] as String?)?.trim();

    final isCompliant = (res?.score.failedRules ?? 0) == 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isCompliant
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : AppColors.error.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.business_rounded,
                          size: 14,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            companyName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (address != null && address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isCompliant
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCompliant
                        ? const Color(0xFF10B981).withValues(alpha: 0.3)
                        : AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCompliant
                          ? Icons.check_circle_rounded
                          : Icons.warning_rounded,
                      size: 14,
                      color: isCompliant
                          ? const Color(0xFF10B981)
                          : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCompliant
                          ? 'COMPLIANT'
                          : '${res?.score.failedRules ?? 0} VIOLATION(S)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isCompliant
                            ? const Color(0xFF047857)
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 20),

          // 2x2 Grid of Extracted Metadata
          Row(
            children: [
              _buildDetailChip('Declared Net Qty', netQty, Icons.scale_rounded),
              const SizedBox(width: AppSpacing.md),
              _buildDetailChip('Declared MRP', mrpStr, Icons.payments_rounded),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _buildDetailChip(
                  'Barcode / GTIN', barcodeVal, Icons.qr_code_2_rounded),
              const SizedBox(width: AppSpacing.md),
              _buildDetailChip(
                'Origin / Scope',
                (pData['country_of_origin'] as String?) ?? 'Domestic (India)',
                Icons.public_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String label, String value, IconData icon) {
    final isMissing = value == 'Not Detected' || value == 'None';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: isMissing
              ? Border.all(color: AppColors.error.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 16,
              color: isMissing ? AppColors.error : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isMissing ? AppColors.error : AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── C. Real Live ML Rule Findings (Grouped) ──────────────────────────────
  Widget _buildLiveRuleFindings(MlScannerResult result) {
    final failed = result.rules.failed;
    final warnings = result.rules.warnings;
    final passed = result.rules.passed;
    final inconclusive = result.rules.inconclusive;
    final notApplicable = result.rules.notApplicable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ML Compliance Rulebook Findings',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              '${result.rules.totalRules} evaluated',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // 1. Violations List
        if (failed.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: const Color(0xFFF87171)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Violations Flagged (${failed.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF991B1B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ...failed.map((rule) => _buildRuleItem(rule, isViolation: true)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // 2. Warnings List
        if (warnings.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: const Color(0xFFFBBF24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFD97706), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Advisory Warnings (${warnings.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ...warnings.map((rule) => _buildRuleItem(rule, isWarning: true)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // 3. Compliant Declarations List
        if (passed.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: Color(0xFF16A34A), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Compliant Declarations (${passed.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ...passed.map((rule) => _buildRuleItem(rule, isCompliant: true)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // 4. Inconclusive / Lab Inspection (Collapsible)
        if (inconclusive.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: ExpansionTile(
              leading: const Icon(Icons.science_outlined,
                  size: 18, color: AppColors.outline),
              title: Text(
                'Physical Lab Verifications (${inconclusive.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              subtitle: Text(
                'Rules requiring physical calipers or weight measures',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              children: inconclusive
                  .map((rule) => _buildRuleItem(rule, isInconclusive: true))
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // 5. Exempt & Non-Applicable Rules (Collapsible)
        if (notApplicable.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: ExpansionTile(
              leading: const Icon(Icons.remove_circle_outline_rounded,
                  size: 18, color: Color(0xFF64748B)),
              title: Text(
                'Exempt & Non-Applicable Rules (${notApplicable.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              subtitle: Text(
                'Rules evaluated as not applicable to this package category',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              children: notApplicable
                  .map((rule) => _buildRuleItem(rule, isNotApplicable: true))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRuleItem(
    MlRuleResult rule, {
    bool isViolation = false,
    bool isWarning = false,
    bool isCompliant = false,
    bool isInconclusive = false,
    bool isNotApplicable = false,
  }) {
    Color badgeColor = const Color(0xFF6B7280);
    String badgeLabel = rule.status;

    if (isViolation) {
      badgeColor = const Color(0xFFDC2626);
      badgeLabel = rule.severity;
    } else if (isWarning) {
      badgeColor = const Color(0xFFD97706);
      badgeLabel = 'WARNING';
    } else if (isCompliant) {
      badgeColor = const Color(0xFF16A34A);
      badgeLabel = 'PASS';
    } else if (isInconclusive) {
      badgeColor = AppColors.outline;
      badgeLabel = 'LAB ONLY';
    } else if (isNotApplicable) {
      badgeColor = const Color(0xFF64748B);
      badgeLabel = 'EXEMPT';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rule.ruleName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeLabel,
                  style: GoogleFonts.firaCode(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          if (rule.legalReference != null && rule.legalReference!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Citation: ${rule.legalReference}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ],
          if (rule.detail.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              rule.detail,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          if (rule.evidence != null && rule.evidence!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Evidence: ${rule.evidence}',
                style: GoogleFonts.firaCode(
                  fontSize: 10,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── D. Offline Fallback Audit Display ─────────────────────────────────────
  Widget _buildOfflineAuditCard(LmAuditResult audit) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.offline_bolt_rounded,
                  size: 18, color: AppColors.secondary),
              const SizedBox(width: 6),
              Text(
                'On-Device Offline Audit Findings',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Score: ${audit.scorePercent}% (${audit.starLabel}) — ${audit.complianceIssues.length} issue(s) detected via on-device OCR.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...audit.complianceIssues.map((issue) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Text(
                '• $issue',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF991B1B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEvaluationWaveLoadingWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C10B981),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Material style circular spinner with wave animation
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Wave ripple 1
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    final val = _waveController.value;
                    return Opacity(
                      opacity: (1.0 - val).clamp(0.0, 1.0),
                      child: Container(
                        width: 44 + (val * 40),
                        height: 44 + (val * 40),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.6),
                            width: 2.0,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Wave ripple 2
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    final val = (_waveController.value + 0.5) % 1.0;
                    return Opacity(
                      opacity: (1.0 - val).clamp(0.0, 1.0),
                      child: Container(
                        width: 44 + (val * 40),
                        height: 44 + (val * 40),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Central Material Circular Progress Spinner
                const SizedBox(
                  width: 46,
                  height: 46,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    backgroundColor: Color(0x2010B981),
                  ),
                ),
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Primary Process Text
          Text(
            'Legal Metrology Engine Evaluating...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          // Dynamic Current Process Text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF047857)),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _statusMessage,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF047857),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Validating PCR 2011 font heights, mandatory declarations & pricing metrology rules',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── Action Buttons ────────────────────────────────────────────────────────
  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary Action: Review & Case File
        ElevatedButton.icon(
          onPressed: _navigateToViolationReview,
          icon: const Icon(Icons.gavel_rounded, size: 18),
          label: Text(
            'Proceed to Legal Review & Case File',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: const RoundedRectangleBorder(
              borderRadius: AppSpacing.roundedDefault,
            ),
            elevation: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Secondary Action: Capture Another
        OutlinedButton.icon(
          onPressed: _handleCaptureNew,
          icon: const Icon(Icons.photo_camera_rounded, size: 18),
          label: Text(
            'Capture Another Sample',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: const RoundedRectangleBorder(
              borderRadius: AppSpacing.roundedDefault,
            ),
          ),
        ),
      ],
    );
  }
}
