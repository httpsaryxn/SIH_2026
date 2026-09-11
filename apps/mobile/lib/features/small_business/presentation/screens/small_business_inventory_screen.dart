import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/motion/motion.dart';
import '../../data/models/small_business_label_model.dart';
import '../../data/repositories/small_business_label_repository.dart';
import '../widgets/product_image_widget.dart';
import 'create_label_declaration_screen.dart';
import 'label_review_export_screen.dart';

/// Full-featured Inventory screen for Small Business owners.
/// Displays all labels created, reviewed, or drafted, with search,
/// category filtering, status segmentation, and fast redirection.
class SmallBusinessInventoryScreen extends StatefulWidget {
  final VoidCallback? onLabelUpdated;

  const SmallBusinessInventoryScreen({super.key, this.onLabelUpdated});

  @override
  State<SmallBusinessInventoryScreen> createState() =>
      _SmallBusinessInventoryScreenState();
}

class _SmallBusinessInventoryScreenState
    extends State<SmallBusinessInventoryScreen> {
  final SmallBusinessLabelRepository _repository =
      SmallBusinessLabelRepository();
  final TextEditingController _searchController = TextEditingController();

  List<SmallBusinessLabelModel> _allLabels = [];
  List<SmallBusinessLabelModel> _filteredLabels = [];
  bool _isLoading = true;

  String _selectedStatusFilter = 'All';
  String? _selectedCategoryFilter;

  final List<String> _categories = [
    'All Categories',
    'Pickles & Condiments',
    'Spices & Seasonings',
    'Honey & Natural Sweeteners',
    'Dairy & Ghee Products',
    'Edible Oils & Cold Pressed Oils',
    'Snacks & Namkeen',
    'Grains, Flours & Pulses',
    'Beverages & Tea/Coffee',
    'Bakery & Confectionery',
    'Organic & Health Foods',
  ];

  @override
  void initState() {
    super.initState();
    _loadInventory();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    try {
      final labels = await _repository.fetchLabels().timeout(
            const Duration(seconds: 5),
            onTimeout: () => _repository.getCachedLabels(),
          );
      if (mounted) {
        setState(() {
          _allLabels = labels;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _allLabels = _repository.getCachedLabels();
          _isLoading = false;
        });
        _applyFilters();
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredLabels = _allLabels.where((label) {
        // Status filter
        if (_selectedStatusFilter == 'Ready') {
          if (label.status != 'ready' && label.status != 'published') {
            return false;
          }
        } else if (_selectedStatusFilter == 'Needs Review') {
          if (label.status != 'needs_review') return false;
        } else if (_selectedStatusFilter == 'Drafts') {
          if (label.status != 'draft') return false;
        }

        // Category filter
        if (_selectedCategoryFilter != null &&
            _selectedCategoryFilter != 'All Categories') {
          if (label.productCategory.toLowerCase() !=
              _selectedCategoryFilter!.toLowerCase()) {
            return false;
          }
        }

        // Search query
        if (query.isNotEmpty) {
          final pName = label.productName.toLowerCase();
          final bName = label.brandName.toLowerCase();
          final cat = label.productCategory.toLowerCase();
          final batch = label.batchNumber.toLowerCase();
          final fssai = label.fssaiLicenseNumber.toLowerCase();
          if (!pName.contains(query) &&
              !bName.contains(query) &&
              !cat.contains(query) &&
              !batch.contains(query) &&
              !fssai.contains(query)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _openLabel(SmallBusinessLabelModel label) {
    if (label.status == 'draft') {
      Navigator.of(context)
          .push(
            DrillInPageRoute(
              page: CreateLabelDeclarationScreen(initialLabel: label),
            ),
          )
          .then((_) {
            _loadInventory();
            widget.onLabelUpdated?.call();
          });
    } else {
      Navigator.of(context)
          .push(
            DrillInPageRoute(
              page: LabelReviewExportScreen(
                labelModel: label,
                brandName: label.brandName,
                productName: label.productName,
                productCategory: label.productCategory,
                netQuantity: '${label.netQuantity} ${label.netQuantityUnit}',
                mrp: label.mrp,
              ),
            ),
          )
          .then((_) {
            _loadInventory();
            widget.onLabelUpdated?.call();
          });
    }
  }

  void _startCreatingLabel() {
    Navigator.of(context)
        .push(
          DrillInPageRoute(
            page: const CreateLabelDeclarationScreen(
              initialLabel: SmallBusinessLabelModel(),
            ),
          ),
        )
        .then((_) {
          _loadInventory();
          widget.onLabelUpdated?.call();
        });
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter by Category',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final isSelected =
                            (cat == 'All Categories' &&
                                _selectedCategoryFilter == null) ||
                            _selectedCategoryFilter == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategoryFilter =
                                  cat == 'All Categories' ? null : cat;
                            });
                            _applyFilters();
                            Navigator.of(ctx).pop();
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                            fontSize: 12.5,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.outlineVariant,
                              width: 1,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int get _readyCount => _allLabels
      .where((l) => l.status == 'ready' || l.status == 'published')
      .length;
  int get _needsReviewCount =>
      _allLabels.where((l) => l.status == 'needs_review').length;
  int get _draftsCount =>
      _allLabels.where((l) => l.status == 'draft').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Label Inventory',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              '${_allLabels.length} labels drafted and cataloged',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Pressable(
              onPressed: _startCreatingLabel,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'New Label',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.surfaceVariant.withValues(alpha: 0.6),
            height: 1.0,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadInventory,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Search Bar & Filter Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: 'Search inventory by title or barcode...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: AppColors.onSurfaceVariant,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      _applyFilters();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Pressable(
                      onPressed: _showCategoryPicker,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _selectedCategoryFilter != null
                              ? AppColors.primaryContainer
                              : AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedCategoryFilter != null
                                ? AppColors.primary
                                : AppColors.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.filter_list_rounded,
                            size: 22,
                            color: _selectedCategoryFilter != null
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Category Filter Active Banner
            if (_selectedCategoryFilter != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedCategoryFilter!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                setState(() => _selectedCategoryFilter = null);
                                _applyFilters();
                              },
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Status Segments
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    _buildStatusChip('All', _allLabels.length),
                    const SizedBox(width: 8),
                    _buildStatusChip('Ready', _readyCount),
                    const SizedBox(width: 8),
                    _buildStatusChip('Needs Review', _needsReviewCount),
                    const SizedBox(width: 8),
                    _buildStatusChip('Drafts', _draftsCount),
                  ],
                ),
              ),
            ),

            // List Content
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_filteredLabels.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            size: 30,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Labels Found',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _searchController.text.isNotEmpty ||
                                  _selectedCategoryFilter != null ||
                                  _selectedStatusFilter != 'All'
                              ? 'Try adjusting your search terms or filters.'
                              : 'Create your first product label to populate your catalog.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Pressable(
                          onPressed: _startCreatingLabel,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Create First Label',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final label = _filteredLabels[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: SlideFadeEntrance(
                          index: index.clamp(0, 5),
                          child: _buildInventoryCard(label),
                        ),
                      );
                    },
                    childCount: _filteredLabels.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, int count) {
    final isSelected = _selectedStatusFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedStatusFilter = label);
        _applyFilters();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.6),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.surfaceVariant.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard(SmallBusinessLabelModel label) {
    final isReady = label.status == 'ready' || label.status == 'published';
    final isNeedsReview = label.status == 'needs_review';

    Color statusColor;
    String statusText;
    if (isReady) {
      statusColor = const Color(0xFF10B981);
      statusText = 'Ready';
    } else if (isNeedsReview) {
      statusColor = const Color(0xFFD97706);
      statusText = 'Needs Review';
    } else {
      statusColor = AppColors.onSurfaceVariant;
      statusText = 'Draft';
    }

    final displayName = label.productName.isNotEmpty
        ? label.productName
        : (label.brandName.isNotEmpty ? label.brandName : 'Untitled Label');

    return Pressable(
      onPressed: () => _openLabel(label),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.45),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 54,
                height: 54,
                child: ProductImageWidget(
                  imageUrl: label.logoUrl ?? '',
                  category: label.productCategory,
                  width: 54,
                  height: 54,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${label.brandName.isNotEmpty ? label.brandName : "Brand"} • ${label.productCategory.isNotEmpty ? label.productCategory : "General"}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (label.netQuantity.isNotEmpty) ...[
                        Text(
                          '${label.netQuantity} ${label.netQuantityUnit}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (label.mrp.isNotEmpty) ...[
                        Text(
                          '₹${label.mrp}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (label.fssaiLicenseNumber.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_user_rounded,
                                size: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'FSSAI: ${label.fssaiLicenseNumber.length > 8 ? "...${label.fssaiLicenseNumber.substring(label.fssaiLicenseNumber.length - 6)}" : label.fssaiLicenseNumber}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Trailing Chevron
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
