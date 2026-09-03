import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/small_business_label_model.dart';
import '../../data/repositories/small_business_label_repository.dart';
import '../../data/services/notification_service.dart';
import '../widgets/continue_working_section.dart';
import '../widgets/create_label_hero_card.dart';
import '../widgets/get_inspired_section.dart';
import '../widgets/studio_bottom_nav.dart';
import '../widgets/studio_header.dart';
import '../widgets/studio_search_bar.dart';
import '../widgets/your_labels_section.dart';
import 'create_label_declaration_screen.dart';
import 'label_review_export_screen.dart';

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
    _loadStudioData(searchQuery: _searchController.text);
  }

  Future<void> _loadStudioData({String? searchQuery}) async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _repository.fetchActiveDraft().timeout(
              const Duration(seconds: 5),
              onTimeout: () => _repository.getCachedActiveDraft(),
            ),
        _repository.fetchLabels(searchQuery: searchQuery).timeout(
              const Duration(seconds: 5),
              onTimeout: () => _repository.getCachedLabels(searchQuery: searchQuery),
            ),
      ]);

      final draft = results[0] as SmallBusinessLabelModel?;
      final labels = results[1] as List<SmallBusinessLabelModel>;

      if (mounted) {
        setState(() {
          _activeDraft = draft;
          _labels = labels;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _labels = _repository.getCachedLabels(searchQuery: searchQuery);
          _isLoading = false;
        });
      }
    }
  }

  void _onStartCreatingLabel() {
    // Start with completely fresh empty label
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
              builder:
                  (context) =>
                      CreateLabelDeclarationScreen(initialLabel: _activeDraft),
            ),
          )
          .then((_) => _loadStudioData());
    } else {
      _onStartCreatingLabel();
    }
  }

  void _onLabelTap(LabelItemData item) {
    if (item.rawModel != null) {
      final model = item.rawModel!;
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder:
                  (context) => LabelReviewExportScreen(
                    brandName: model.brandName,
                    productName: model.productName,
                    productCategory: model.productCategory,
                    netQuantity: '${model.netQuantity} ${model.netQuantityUnit}',
                    mrp: model.mrp.startsWith('₹') ? model.mrp : '₹ ${model.mrp}',
                    labelModel: model,
                  ),
            ),
          )
          .then((_) => _loadStudioData());
    }
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

  void _onSampleTap(SampleLabelData sample) {
    final templateModel = SmallBusinessLabelModel(
      brandName: 'Desi Harvest',
      productName: sample.title,
      productCategory: sample.category,
      typeFlavour: 'Heritage Special',
      mrp: '199.00',
    );

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder:
                (context) =>
                    CreateLabelDeclarationScreen(initialLabel: templateModel),
          ),
        )
        .then((_) => _loadStudioData());
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
                // Top drag handle pill
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

  @override
  Widget build(BuildContext context) {
    // Apply active status and category filters to labels
    var filteredLabels = _labels;

    if (_selectedStatusFilter == 'Ready') {
      filteredLabels = filteredLabels.where((l) => l.status == 'ready').toList();
    } else if (_selectedStatusFilter == 'Needs Review') {
      filteredLabels = filteredLabels.where((l) => l.status == 'needs_review').toList();
    } else if (_selectedStatusFilter == 'Drafts') {
      filteredLabels = filteredLabels.where((l) => l.status == 'draft').toList();
    }

    if (_selectedCategoryFilter != null && _selectedCategoryFilter!.isNotEmpty) {
      filteredLabels = filteredLabels.where((l) => l.productCategory == _selectedCategoryFilter).toList();
    }

    final labelItems = filteredLabels
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
                  onProfileTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Small Business Profile & FSSAI Details'),
                        backgroundColor: AppColors.brandDeepGreen,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),

                // 2. Search Bar with working category filter icon
                StudioSearchBar(
                  controller: _searchController,
                  onFilterTap: _showCategoryFilterDialog,
                ),
                const SizedBox(height: 12),

                // 3. Interactive Filter Tabs (All, Ready, Needs Review, Drafts)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All (${_labels.length})',
                        isSelected: _selectedStatusFilter == 'All',
                        onTap: () => setState(() => _selectedStatusFilter = 'All'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Ready',
                        isSelected: _selectedStatusFilter == 'Ready',
                        onTap: () => setState(() => _selectedStatusFilter = 'Ready'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Needs Review',
                        isSelected: _selectedStatusFilter == 'Needs Review',
                        onTap: () => setState(() => _selectedStatusFilter = 'Needs Review'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Drafts',
                        isSelected: _selectedStatusFilter == 'Drafts',
                        onTap: () => setState(() => _selectedStatusFilter = 'Drafts'),
                      ),
                      if (_selectedCategoryFilter != null) ...[
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(_selectedCategoryFilter!),
                          onDeleted: () => setState(() => _selectedCategoryFilter = null),
                          deleteIcon: const Icon(Icons.close_rounded, size: 14),
                          backgroundColor: AppColors.brandDeepGreen.withValues(alpha: 0.1),
                          labelStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandDeepGreen,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Hero Card
                CreateLabelHeroCard(
                  onStartCreating: _onStartCreatingLabel,
                  onAddTap: _onStartCreatingLabel,
                ),
                const SizedBox(height: 24),

                // 5. Continue Working Section
                if (_activeDraft != null && (_selectedStatusFilter == 'All' || _selectedStatusFilter == 'Drafts'))
                  ContinueWorkingSection(
                    draft: _activeDraft,
                    onDraftCardTap: _onDraftTap,
                    onViewDrafts: _onDraftTap,
                    onDeleteDraft: _deleteDraftFromStudio,
                  ),
                if (_activeDraft != null && (_selectedStatusFilter == 'All' || _selectedStatusFilter == 'Drafts'))
                  const SizedBox(height: 24),

                // 6. Your Labels Section
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
                    onSeeAll: () {
                      setState(() {
                        _selectedStatusFilter = 'All';
                        _selectedCategoryFilter = null;
                      });
                    },
                    onLabelTap: _onLabelTap,
                  ),
                const SizedBox(height: 24),

                // 7. Get Inspired / Templates Section
                GetInspiredSection(onSampleTap: _onSampleTap),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: StudioBottomNav(
        currentIndex: _currentNavIndex,
        onTap: (index) {
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandDeepGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.brandDeepGreen : AppColors.outlineVariant,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.brandDeepGreen.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
