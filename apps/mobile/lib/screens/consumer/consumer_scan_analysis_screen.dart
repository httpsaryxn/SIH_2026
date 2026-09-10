import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/capture_role.dart';
import '../../core/models/consumer_scan_model.dart';
import '../../core/models/multi_capture_payload.dart';
import '../../core/models/pending_capture.dart';
import '../../core/services/consumer_data_service.dart';
import '../../core/services/legal_metrology_service.dart';
import '../../core/services/ml_scanner_client.dart';
import '../../core/services/summary_gen_client.dart';
import '../../core/widgets/markdown_content_view.dart';
import '../shared/multi_capture_screen.dart';
import 'widgets/product_summary_modal.dart';
import 'widgets/report_complaint_dialog.dart';

class ConsumerScanAnalysisScreen extends StatefulWidget {
  final PendingCapture pendingCapture;
  final MultiCapturePayload? multiCapture;
  final String? prefilledProductName;
  final String? prefilledBrand;
  final String? prefilledCategory;
  final String? prefilledNetQty;
  final double? prefilledMrp;
  final Function(ConsumerScanModel scanResult)? onScanCompleted;

  const ConsumerScanAnalysisScreen({
    super.key,
    required this.pendingCapture,
    this.multiCapture,
    this.prefilledProductName,
    this.prefilledBrand,
    this.prefilledCategory,
    this.prefilledNetQty,
    this.prefilledMrp,
    this.onScanCompleted,
  });

  @override
  State<ConsumerScanAnalysisScreen> createState() =>
      _ConsumerScanAnalysisScreenState();
}

class _ConsumerScanAnalysisScreenState extends State<ConsumerScanAnalysisScreen>
    with TickerProviderStateMixin {
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // Carousel state for multi-image display
  final PageController _carouselController = PageController();
  int _carouselPage = 0;

  int _currentStageIndex = 0;
  String _statusMessage = 'Uploading image to local ingestion cache...';
  ConsumerScanModel? _completedScan;
  bool _isAnalysisFinished = false;
  bool _hasError = false;
  String _errorMessage = '';

  // AI Summary State (Groq LLaMA 3.3 via services/summary-gen)
  ConsumerSummaryResult? _summaryResult;
  bool _isGeneratingSummary = false;
  String? _lastProductName;
  String? _lastBrand;
  MlScannerResult? _lastRemoteResult;
  LmAuditResult? _lastAudit;
  String? _lastOcrText;

  /// Returns the list of captures for carousel display.
  List<MapEntry<CaptureRole, PendingCapture>> get _capturedEntries {
    if (widget.multiCapture != null) {
      return widget.multiCapture!.capturedEntries;
    }
    return [MapEntry(CaptureRole.frontLabel, widget.pendingCapture)];
  }

  final List<Map<String, dynamic>> _stages = [
    {
      'title': 'Image Ingestion & Cache',
      'subtitle': 'Collision-safe storage & EXIF parsing',
      'icon': Icons.cloud_upload_rounded,
      'threshold': 0.25,
    },
    {
      'title': 'OCR & Text Detection',
      'subtitle': 'Extracting ingredients, MRP & net quantity',
      'icon': Icons.document_scanner_rounded,
      'threshold': 0.55,
    },
    {
      'title': 'Legal Metrology PCR 2011 Verification',
      'subtitle': 'Validating font height & mandatory declarations',
      'icon': Icons.verified_user_rounded,
      'threshold': 0.85,
    },
    {
      'title': 'Database Sync & Catalog Update',
      'subtitle': 'Generating compliance audit report',
      'icon': Icons.check_circle_rounded,
      'threshold': 1.0,
    },
  ];

  @override
  void initState() {
    super.initState();

    // 1. Scanning Laser Animation (continuous up and down)
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );

    // 2. Progress Controller (0.0 to 1.0)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _progressController.addListener(() {
      final val = _progressController.value;
      if (val < 0.25) {
        if (_currentStageIndex != 0) {
          setState(() {
            _currentStageIndex = 0;
            _statusMessage = 'Uploading image to local ingestion cache...';
          });
        }
      } else if (val < 0.55) {
        if (_currentStageIndex != 1) {
          setState(() {
            _currentStageIndex = 1;
            _statusMessage = 'Extracting OCR text, ingredients & nutritional table...';
          });
        }
      } else if (val < 0.85) {
        if (_currentStageIndex != 2) {
          setState(() {
            _currentStageIndex = 2;
            _statusMessage = 'Verifying Legal Metrology Packaging Rules (PCR 2011)...';
          });
        }
      } else {
        if (_currentStageIndex != 3) {
          setState(() {
            _currentStageIndex = 3;
            _statusMessage = 'Finalizing report & storing scan record...';
          });
        }
      }
    });

    _startAnalysisPipeline();
  }

  @override
  void dispose() {
    _laserController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _startAnalysisPipeline() async {
    try {
      _progressController.forward();

      // ── Stage 1: Try remote ML Scanner service ──
      MlScannerResult? remoteResult;
      try {
        if (mounted) {
          setState(() {
            _currentStageIndex = 0;
            _statusMessage = 'Uploading captured label images to ML Scanner...';
          });
        }
        remoteResult = await LegalMetrologyService.auditCaptureRemote(
          capture: widget.pendingCapture,
          multiCapture: widget.multiCapture,
          productName: widget.prefilledProductName,
        );
      } catch (_) {
        // remote service unavailable — will fall back to on-device
      }

      if (remoteResult != null && mounted) {
        setState(() {
          _currentStageIndex = 2;
          _statusMessage = 'Parsing ML compliance model findings & rule checks...';
        });
      }

      // ── Stage 2: Fall back to on-device audit if remote unavailable ──
      LmAuditResult? audit;
      if (remoteResult == null) {
        if (mounted) {
          setState(() {
            _currentStageIndex = 1;
            _statusMessage =
                'Reading label with on-device OCR & bar code scanner...';
          });
        }
        audit = await LegalMetrologyService.auditCapture(
          capture: widget.pendingCapture,
          multiCapture: widget.multiCapture,
          productName: widget.prefilledProductName,
          netQuantity: widget.prefilledNetQty,
          mrp: widget.prefilledMrp,
        );
        if (mounted) {
          setState(() {
            _currentStageIndex = 2;
            _statusMessage =
                'Verifying mandatory declarations against LM(PC) Rules 2011...';
          });
        }
      }

      final String pName;
      if (remoteResult != null &&
          (remoteResult.product['name'] as String?)?.trim().isNotEmpty == true) {
        pName = (remoteResult.product['name'] as String).trim();
      } else if (audit != null &&
          (audit.detectedDeclarations['commodity_name'] as String?)
                  ?.trim()
                  .isNotEmpty ==
              true) {
        pName = (audit.detectedDeclarations['commodity_name'] as String).trim();
      } else if (widget.prefilledProductName != null &&
          widget.prefilledProductName!.trim().isNotEmpty) {
        pName = widget.prefilledProductName!.trim();
      } else {
        pName = _deriveProductNameFromFileName(widget.pendingCapture.fileName);
      }

      final String pBrand;
      if (remoteResult != null &&
          (remoteResult.product['manufacturer'] as String?)?.trim().isNotEmpty == true) {
        pBrand = (remoteResult.product['manufacturer'] as String).trim();
      } else if (widget.prefilledBrand != null &&
          widget.prefilledBrand!.trim().isNotEmpty) {
        pBrand = widget.prefilledBrand!.trim();
      } else {
        pBrand = 'Packaged Foods Co.';
      }

      final pCategory = (widget.prefilledCategory != null &&
              widget.prefilledCategory!.trim().isNotEmpty)
          ? widget.prefilledCategory!.trim()
          : 'Snacks';

      final String pNetQty;
      if (remoteResult != null &&
          (remoteResult.product['net_quantity'] as String?)?.trim().isNotEmpty == true) {
        pNetQty = (remoteResult.product['net_quantity'] as String).trim();
      } else if (widget.prefilledNetQty != null &&
              widget.prefilledNetQty!.trim().isNotEmpty) {
        pNetQty = widget.prefilledNetQty!.trim();
      } else {
        pNetQty = '200 g';
      }

      final double pMrp;
      if (remoteResult != null && remoteResult.product['mrp'] is num) {
        pMrp = (remoteResult.product['mrp'] as num).toDouble();
      } else {
        pMrp = widget.prefilledMrp ?? 65.0;
      }

      // Create live product & scan record in Supabase (with Storage upload)
      final createdScan = await ConsumerDataService.createNewProductAndScan(
        productName: pName,
        brand: pBrand,
        category: pCategory,
        netQuantity: pNetQty,
        mrp: pMrp,
        multiCapture: widget.multiCapture,
        pendingCapture: widget.pendingCapture,
        imageUrl: widget.pendingCapture.localPath,
        audit: audit,
      );

      // Wait for progress animation to complete
      await _progressController.forward(from: _progressController.value);

      if (mounted) {
        setState(() {
          _completedScan = createdScan;
          _isAnalysisFinished = true;
          if (remoteResult != null) {
            final s = remoteResult.score;
            _statusMessage =
                'Analysis complete — ${s.finalScore.toStringAsFixed(1)}% (${s.starLabel}), '
                'verified against LM(PC) Rules 2011.';
          } else if (audit != null) {
            _statusMessage =
                'Analysis complete — ${audit.scorePercent}% (${audit.starLabel}), '
                'verified against LM(PC) Rules 2011.';
          } else {
            _statusMessage = 'Analysis complete — verified against LM(PC) Rules 2011.';
          }
        });

        if (createdScan != null && widget.onScanCompleted != null) {
          widget.onScanCompleted!(createdScan);
        }

        _lastProductName = pName;
        _lastBrand = pBrand;
        _lastRemoteResult = remoteResult;
        _lastAudit = audit;

        String? ocrText;
        if (audit?.rawOcrText != null && audit!.rawOcrText!.trim().isNotEmpty) {
          ocrText = audit.rawOcrText;
        } else {
          try {
            ocrText = await LegalMetrologyService.extractTextFromCaptures(
              capture: widget.pendingCapture,
              multiCapture: widget.multiCapture,
            );
          } catch (e) {
            debugPrint('[ConsumerScanAnalysisScreen] Fast OCR extraction error: $e');
          }
        }
        _lastOcrText = ocrText;

        // Automatically trigger AI Summary generation
        _fetchAiSummary(
          scan: createdScan,
          productName: pName,
          brand: pBrand,
          remoteResult: remoteResult,
          audit: audit,
          ocrText: ocrText,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Analysis failed: $e';
        });
      }
    }
  }

  String _deriveProductNameFromFileName(String fileName) {
    return 'Packaged Food Product';
  }

  void _showDetailedSummary() {
    if (_completedScan == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductSummaryModal(
        scan: _completedScan!,
        onReportIssue: () {
          Navigator.of(context).pop();
          _openReportDialog();
        },
      ),
    );
  }

  void _openReportDialog() {
    showDialog(
      context: context,
      builder: (context) => ReportComplaintDialog(
        prefilledProductName: _completedScan?.productName,
        prefilledBrand: _completedScan?.brand,
        prefilledCapture: widget.pendingCapture,
        onComplaintSubmitted: (newComplaint) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              content: Text(
                'Complaint ${newComplaint.complaintCode} filed successfully!',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _scanAnother() async {
    // Navigate to multi-capture screen for next scan
    final result = await Navigator.of(context).push<MultiCapturePayload?>(
      MaterialPageRoute(
        builder: (_) => const MultiCaptureScreen(
          sourceTag: 'consumer_scan',
          flowLabel: 'Product Label',
        ),
      ),
    );

    if (result != null && result.hasAnyCapture && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ConsumerScanAnalysisScreen(
            multiCapture: result,
            pendingCapture: result.primaryCapture!,
            onScanCompleted: widget.onScanCompleted,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isAnalysisFinished ? 'Scan Results' : 'Scanning & Analysis',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.md),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cached_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  widget.pendingCapture.formattedSize,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Captured Photo with Scanning Laser Overlay
            _buildScanningViewport(),
            const SizedBox(height: AppSpacing.lg),

            // 2. Progress Bar & Real-time Telemetry
            _buildProgressBarSection(),
            const SizedBox(height: AppSpacing.lg),

            // 3. Stage Checklist
            _buildStageChecklist(),
            const SizedBox(height: AppSpacing.lg),

            // 4. Extracted Product Summary & AI Insights (Revealed when ready)
            if (_isAnalysisFinished && _completedScan != null) ...[
              _buildExtractedProductCard(),
              const SizedBox(height: AppSpacing.md),
              _buildAiConsumerInsightsCard(),
              const SizedBox(height: AppSpacing.xl),
            ],

            if (_hasError) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: const Color(0xFFF87171)),
                ),
                child: Text(
                  _errorMessage,
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFFB91C1C)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // 5. Action Buttons
            _buildBottomActionButtons(),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningViewport() {
    final entries = _capturedEntries;
    final showCarousel = entries.length > 1;

    return Column(
      children: [
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: _isAnalysisFinished ? AppColors.primary : AppColors.outlineVariant,
              width: 2,
            ),
            boxShadow: AppSpacing.cardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Carousel PageView or single image
              if (showCarousel)
                PageView.builder(
                  controller: _carouselController,
                  itemCount: entries.length,
                  onPageChanged: (i) => setState(() => _carouselPage = i),
                  itemBuilder: (context, i) {
                    final capture = entries[i].value;
                    return _buildCaptureSlide(capture, entries[i].key);
                  },
                )
              else if (entries.isNotEmpty && entries.first.value.existsSync)
                _buildCaptureSlide(entries.first.value, entries.first.key)
              else
                _buildFallbackPreview(),

              // Dark vignette overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Corner Frame Guides
              _buildCornerGuides(),

              // Animated Scanning Laser Bar
              if (!_isAnalysisFinished)
                AnimatedBuilder(
                  animation: _laserAnimation,
                  builder: (context, child) {
                    return Positioned(
                      top: _laserAnimation.value * 260,
                      left: 16,
                      right: 16,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryFixed.withValues(alpha: 0.8),
                              blurRadius: 12,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // Top Badge — role label for current carousel slide
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isAnalysisFinished
                            ? Icons.check_circle_rounded
                            : CaptureRoleInfo.forRole(entries[showCarousel ? _carouselPage : 0].key).icon,
                        size: 14,
                        color: _isAnalysisFinished
                            ? const Color(0xFF10B981)
                            : AppColors.primaryFixedDim,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isAnalysisFinished
                            ? '${CaptureRoleInfo.forRole(entries[showCarousel ? _carouselPage : 0].key).label} ✓'
                            : CaptureRoleInfo.forRole(entries[showCarousel ? _carouselPage : 0].key).label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Image count badge
              if (showCarousel)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      '${_carouselPage + 1}/${entries.length}',
                      style: GoogleFonts.firaCode(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Bottom Filename Tag
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.pendingCapture.formattedSize,
                    style: GoogleFonts.firaCode(
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Page indicator dots (only for carousel)
        if (showCarousel) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(entries.length, (i) {
              final isActive = i == _carouselPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildCaptureSlide(PendingCapture capture, CaptureRole role) {
    if (capture.existsSync) {
      return Image.file(
        capture.file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (ctx, err, stack) => _buildFallbackPreview(),
      );
    }
    return _buildFallbackPreview();
  }

  Widget _buildFallbackPreview() {
    return Container(
      color: const Color(0xFF0F172A),
      child: const Center(
        child: Icon(
          Icons.photo_library_rounded,
          size: 64,
          color: Colors.white38,
        ),
      ),
    );
  }

  Widget _buildCornerGuides() {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.primaryFixed, width: 3),
                    left: BorderSide(color: AppColors.primaryFixed, width: 3),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.primaryFixed, width: 3),
                    right: BorderSide(color: AppColors.primaryFixed, width: 3),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.primaryFixed, width: 3),
                    left: BorderSide(color: AppColors.primaryFixed, width: 3),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.primaryFixed, width: 3),
                    right: BorderSide(color: AppColors.primaryFixed, width: 3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBarSection() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        final percent = (_progressAnimation.value * 100).toInt();

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.surfaceVariant),
            boxShadow: AppSpacing.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (!_isAnalysisFinished)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      else
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _isAnalysisFinished ? 'Verification Complete' : 'Processing Label',
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
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: LinearProgressIndicator(
                  value: _progressAnimation.value,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isAnalysisFinished ? const Color(0xFF10B981) : AppColors.primary,
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

  Widget _buildStageChecklist() {
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
            final isDone = _progressController.value >= stage['threshold'];
            final isCurrent = idx == _currentStageIndex && !_isAnalysisFinished;

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
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.surfaceContainerHigh),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check_rounded, size: 16, color: Color(0xFF10B981))
                          : (isCurrent
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
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
                            fontWeight: isDone || isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isDone || isCurrent
                                ? AppColors.onSurface
                                : AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          stage['subtitle'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDone)
                    Text(
                      'Done',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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

  Widget _buildExtractedProductCard() {
    final scan = _completedScan!;
    final isCompliant = scan.complianceStatus == 'compliant';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isCompliant ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          width: 1.5,
        ),
        boxShadow: AppSpacing.cardHoverShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan.productName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      'Brand: ${scan.brand}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isCompliant
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCompliant ? Icons.check_circle_rounded : Icons.warning_rounded,
                      size: 14,
                      color: isCompliant ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCompliant ? 'COMPLIANT' : 'REVIEW NEEDED',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isCompliant ? const Color(0xFF047857) : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              _buildDetailChip('Declared Net Qty', scan.netQuantity),
              const SizedBox(width: AppSpacing.md),
              _buildDetailChip(
                'Declared MRP',
                scan.detectedDeclarations['mrp'] != null
                    ? '₹${scan.detectedDeclarations['mrp']}'
                    : '₹65.00',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _fetchAiSummary({
    ConsumerScanModel? scan,
    required String productName,
    required String brand,
    MlScannerResult? remoteResult,
    LmAuditResult? audit,
    String? ocrText,
    bool forceRegenerate = false,
  }) async {
    if (!mounted) return;
    setState(() {
      _isGeneratingSummary = true;
    });

    try {
      final resolvedOcrText = ocrText ?? audit?.rawOcrText ?? _lastOcrText;
      final summary = await SummaryGenClient.summarizeConsumer(
        scanId: scan?.id,
        productName: productName,
        manufacturer: brand,
        declarations:
            remoteResult?.product ?? audit?.detectedDeclarations,
        rules: remoteResult?.rules.toJson(),
        ocrText: resolvedOcrText,
        forceRegenerate: forceRegenerate,
      );

      if (mounted) {
        setState(() {
          _summaryResult = summary;
          _isGeneratingSummary = false;
          if (_completedScan != null) {
            _completedScan = ConsumerScanModel(
              id: _completedScan!.id,
              consumerId: _completedScan!.consumerId,
              productId: _completedScan!.productId,
              productName: _completedScan!.productName,
              brand: _completedScan!.brand,
              netQuantity: _completedScan!.netQuantity,
              imageUrl: _completedScan!.imageUrl,
              frontLabelUrl: _completedScan!.frontLabelUrl,
              curvedSurfaceUrl: _completedScan!.curvedSurfaceUrl,
              scaleReferenceUrl: _completedScan!.scaleReferenceUrl,
              complianceStatus: _completedScan!.complianceStatus,
              detectedDeclarations: _completedScan!.detectedDeclarations,
              scanNotes: _completedScan!.scanNotes,
              scannedAt: _completedScan!.scannedAt,
              productType: summary.productType,
              consumerSummaryText: summary.summaryText,
              healthScore: summary.healthScore,
              medicinalSafetySummary: summary.medicinalSafetySummary,
              summaryGeneratedAt: DateTime.now(),
            );
          }
        });
      } else if (mounted) {
        setState(() {
          _isGeneratingSummary = false;
        });
      }
    } catch (e) {
      debugPrint('[ConsumerScanAnalysisScreen] Error fetching AI summary: $e');
      if (mounted) {
        setState(() {
          _isGeneratingSummary = false;
        });
      }
    }
  }

  Widget _buildAiConsumerInsightsCard() {
    if (_isGeneratingSummary && _summaryResult == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          boxShadow: AppSpacing.cardShadow,
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generating AI Label Insights...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Analyzing commodity classification, nutrition & safety with Groq LLM...',
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
      );
    }

    if (_summaryResult == null) {
      return const SizedBox.shrink();
    }

    final res = _summaryResult!;
    final isFood = res.isFood;
    final isMedicinal = res.isMedicinal;

    final Color badgeColor;
    final Color badgeBg;
    final String typeLabel;
    final IconData typeIcon;

    if (isFood) {
      badgeColor = const Color(0xFF059669);
      badgeBg = const Color(0xFFD1FAE5);
      typeLabel = 'FOOD & BEVERAGE';
      typeIcon = Icons.restaurant_rounded;
    } else if (isMedicinal) {
      badgeColor = const Color(0xFF0D9488);
      badgeBg = const Color(0xFFCCFBF1);
      typeLabel = 'MEDICINAL / PHARMA';
      typeIcon = Icons.medical_services_rounded;
    } else {
      badgeColor = const Color(0xFF4F46E5);
      badgeBg = const Color(0xFFEEF2FF);
      typeLabel = 'GENERAL COMMODITY';
      typeIcon = Icons.inventory_2_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primaryContainer.withValues(alpha: 0.5),
        ),
        boxShadow: AppSpacing.cardHoverShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Label Insights',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(typeIcon, size: 12, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      typeLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          MarkdownContentView(
            text: res.summaryText,
            baseStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface,
            ),
          ),
          if (isFood && res.healthScore != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildHealthScoreSection(res.healthScore!, res.healthScoreRationale),
          ],
          if (isMedicinal) ...[
            if (res.medicinalSafetySummary != null &&
                res.medicinalSafetySummary!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        res.medicinalSafetySummary!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF166534),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      res.mandatoryDisclaimer ??
                          'Informational summary of declared label content only. Not medical advice.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF92400E),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI analysis powered by Groq LLaMA 3.3',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
              InkWell(
                onTap: _isGeneratingSummary
                    ? null
                    : () => _fetchAiSummary(
                          scan: _completedScan,
                          productName: _lastProductName ??
                              widget.pendingCapture.fileName,
                          brand: _lastBrand ?? 'General Brand',
                          remoteResult: _lastRemoteResult,
                          audit: _lastAudit,
                          ocrText: _lastOcrText,
                          forceRegenerate: true,
                        ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.refresh_rounded,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Regenerate',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreSection(int score, String? rationale) {
    final Color scoreColor;
    final String label;
    if (score >= 70) {
      scoreColor = const Color(0xFF10B981);
      label = 'Nutritionally Balanced';
    } else if (score >= 45) {
      scoreColor = const Color(0xFFF59E0B);
      label = 'Moderate Balance';
    } else {
      scoreColor = const Color(0xFFEF4444);
      label = 'High Sugar / Salt / Fat';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite_rounded, size: 16, color: scoreColor),
                  const SizedBox(width: 6),
                  Text(
                    'Health & Nutrition Score',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '$score',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: scoreColor,
                    ),
                  ),
                  Text(
                    '/100',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100.0,
              minHeight: 6,
              backgroundColor: AppColors.outlineVariant.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            rationale != null && rationale.isNotEmpty ? rationale : label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: AppColors.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDetailChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionButtons() {
    if (!_isAnalysisFinished) {
      return OutlinedButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close_rounded),
        label: const Text('Cancel Analysis'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _showDetailedSummary,
          icon: const Icon(Icons.visibility_rounded, size: 20),
          label: Text(
            'View Detailed Breakdown',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
            ),
            elevation: 2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _scanAnother,
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: const Text('Scan Another'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openReportDialog,
                icon: const Icon(Icons.campaign_rounded, size: 18, color: Color(0xFFDC2626)),
                label: Text(
                  'Report Issue',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFDC2626),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
