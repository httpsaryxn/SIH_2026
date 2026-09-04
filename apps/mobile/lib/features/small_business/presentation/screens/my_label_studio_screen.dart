import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/small_business_label_model.dart';
import '../../data/repositories/small_business_label_repository.dart';
import '../../data/services/notification_service.dart';
import '../widgets/continue_working_section.dart';
import '../widgets/create_label_hero_card.dart';
import '../widgets/studio_bottom_nav.dart';
import '../widgets/studio_header.dart';
import '../widgets/studio_search_bar.dart';
import '../widgets/your_labels_section.dart';
import 'create_label_declaration_screen.dart';
import 'label_review_export_screen.dart';
import 'small_business_profile_screen.dart';

class MyLabelStudioScreen extends StatefulWidget {
  const MyLabelStudioScreen({super.key});

  @override
  State<MyLabelStudioScreen> createState() => _MyLabelStudioScreenState();
}

class _MyLabelStudioScreenState extends State<MyLabelStudioScreen> {
  int _currentNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final SmallBusinessLabelRepository _repository =
      SmallBusinessLabelRepository();

  SmallBusinessLabelModel? _activeDraft;
  List<SmallBusinessLabelModel> _allLabels = [];
  List<SmallBusinessLabelModel> _labels = [];
  bool _isLoading = true;

  String _selectedStatusFilter = 'All';
  String? _selectedCategoryFilter;

  final List<String> _filterCategories = [
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
    _loadStudioData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _labels = _allLabels.where((label) {
        // Status filter
        if (_selectedStatusFilter == 'Ready' &&
            label.status != 'ready' &&
            label.status != 'published') {
          return false;
        } else if (_selectedStatusFilter == 'Needs Review' &&
            label.status != 'needs_review') {
          return false;
        } else if (_selectedStatusFilter == 'Drafts' &&
            label.status != 'draft') {
          return false;
        }

        // Category filter
        if (_selectedCategoryFilter != null &&
            _selectedCategoryFilter != 'All Categories' &&
            label.productCategory.toLowerCase() !=
                _selectedCategoryFilter!.toLowerCase()) {
          return false;
        }

        // Search query
        if (query.isNotEmpty) {
          final pName = label.productName.toLowerCase();
          final bName = label.brandName.toLowerCase();
          final cat = label.productCategory.toLowerCase();
          final claims = label.claims.join(' ').toLowerCase();
          final batch = label.batchNumber.toLowerCase();
          if (!pName.contains(query) &&
              !bName.contains(query) &&
              !cat.contains(query) &&
              !claims.contains(query) &&
              !batch.contains(query)) {
            return false;
          }
        }
        return true;
      }).toList();
    });
  }

  Future<void> _loadStudioData() async {
    try {
      final results = await Future.wait([
        _repository.fetchActiveDraft().timeout(
              const Duration(seconds: 5),
              onTimeout: () => _repository.getCachedActiveDraft(),
            ),
        _repository.fetchLabels().timeout(
              const Duration(seconds: 5),
              onTimeout: () => _repository.getCachedLabels(),
            ),
      ]);

      final draft = results[0] as SmallBusinessLabelModel?;
      final labels = results[1] as List<SmallBusinessLabelModel>;

      if (mounted) {
        setState(() {
          _activeDraft = draft;
          _allLabels = labels;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allLabels = _repository.getCachedLabels();
          _isLoading = false;
        });
        _applyFilters();
      }
    }
  }

  void _onStartCreatingLabel() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const CreateLabelDeclarationScreen(
              initialLabel: SmallBusinessLabelModel(),
            ),
          ),
        )
        .then((_) => _loadStudioData());
  }

  void _onDraftTap() {
    if (_activeDraft != null) {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) =>
                  CreateLabelDeclarationScreen(initialLabel: _activeDraft),
            ),
          )
          .then((_) => _loadStudioData());
    }
  }

  void _onLabelTap(LabelItemData item) {
    final label = item.rawModel ??
        _allLabels.firstWhere(
          (l) => l.productName == item.title,
          orElse: () => SmallBusinessLabelModel(productName: item.title),
        );

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => LabelReviewExportScreen(
              labelModel: label,
              brandName: label.brandName,
              productName: label.productName,
              productCategory: label.productCategory,
              netQuantity: '${label.netQuantity} ${label.netQuantityUnit}',
              mrp: label.mrp,
            ),
          ),
        )
        .then((_) => _loadStudioData());
  }

  void _deleteDraftFromStudio() {
    if (_activeDraft == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Text('Delete Draft?'),
          ],
        ),
        content: Text(
          'Are you sure you want to discard the active draft for "${_activeDraft!.productName.isNotEmpty ? _activeDraft!.productName : "Untitled Product"}"?',
          style: const TextStyle(fontSize: 13.5, color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (_activeDraft!.id != null) {
                await _repository.deleteLabel(_activeDraft!.id!);
              }

              SmallBusinessNotificationService().notify(
                title: 'Draft Discarded',
                message: 'Deleted active draft from studio hub.',
                type: NotificationType.warning,
              );

              _loadStudioData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Draft'),
          ),
        ],
      ),
    );
  }

  void _showCategoryFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                    const Text(
                      'Filter by Product Category',
                      style: TextStyle(
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
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _filterCategories.map((cat) {
                          final isSelected =
                              (cat == 'All Categories' && _selectedCategoryFilter == null) ||
                              _selectedCategoryFilter == cat;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategoryFilter = cat == 'All Categories' ? null : cat;
                              });
                              _applyFilters();
                              Navigator.of(ctx).pop();
                            },
                            selectedColor: AppColors.brandDeepGreen,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? AppColors.brandDeepGreen : AppColors.outlineVariant,
                                width: 1,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
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

  void _showProfileSheet() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SmallBusinessProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelItems = _labels
        .map((model) => LabelItemData.fromModel(model))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadStudioData(),
          color: AppColors.brandDeepGreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Studio Header with Notifications & Profile
                StudioHeader(
                  onNotificationTap:
                      () => SmallBusinessNotificationService.showNotificationCenter(context),
                  onProfileTap: _showProfileSheet,
                ),

                // 2. Search Bar with working category filter icon
                StudioSearchBar(
                  controller: _searchController,
                  onFilterTap: _showCategoryFilterDialog,
                ),
                const SizedBox(height: 16),

                // 3. Hero Card
                CreateLabelHeroCard(
                  onStartCreating: _onStartCreatingLabel,
                  onAddTap: _onStartCreatingLabel,
                ),
                const SizedBox(height: 24),

                // 4. Continue Working Section
                if (_activeDraft != null && (_selectedStatusFilter == 'All' || _selectedStatusFilter == 'Drafts'))
                  ContinueWorkingSection(
                    draft: _activeDraft,
                    onDraftCardTap: _onDraftTap,
                    onViewDrafts: _onDraftTap,
                    onDeleteDraft: _deleteDraftFromStudio,
                  ),
                if (_activeDraft != null && (_selectedStatusFilter == 'All' || _selectedStatusFilter == 'Drafts'))
                  const SizedBox(height: 24),

                // 5. Your Labels Section with filter options below the header
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(
                        color: AppColors.brandDeepGreen,
                      ),
                    ),
                  )
                else
                  YourLabelsSection(
                    labels: labelItems,
                    totalCount: _allLabels.length,
                    readyCount: _allLabels
                        .where((l) => l.status == 'ready' || l.status == 'published')
                        .length,
                    needsReviewCount: _allLabels.where((l) => l.status == 'needs_review').length,
                    selectedStatusFilter: _selectedStatusFilter,
                    selectedCategoryFilter: _selectedCategoryFilter,
                    onStatusFilterChanged: (filter) {
                      setState(() => _selectedStatusFilter = filter);
                      _applyFilters();
                    },
                    onClearCategoryFilter: () {
                      setState(() => _selectedCategoryFilter = null);
                      _applyFilters();
                    },
                    onSeeAll: () {
                      setState(() {
                        _selectedStatusFilter = 'All';
                        _selectedCategoryFilter = null;
                      });
                      _applyFilters();
                    },
                    onLabelTap: _onLabelTap,
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: StudioBottomNav(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          if (index == 3) {
            _showProfileSheet();
            return;
          }
          setState(() {
            _currentNavIndex = index;
            if (index == 0) {
              _selectedStatusFilter = 'All';
              _selectedCategoryFilter = null;
            }
          });
          _loadStudioData();
        },
      ),
    );
  }
}
