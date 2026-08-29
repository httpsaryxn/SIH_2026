import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/continue_working_section.dart';
import '../widgets/create_label_hero_card.dart';
import '../widgets/get_inspired_section.dart';
import '../widgets/studio_bottom_nav.dart';
import '../widgets/studio_header.dart';
import '../widgets/studio_search_bar.dart';
import '../widgets/your_labels_section.dart';

import 'create_label_declaration_screen.dart';

class MyLabelStudioScreen extends StatefulWidget {
  const MyLabelStudioScreen({super.key});

  @override
  State<MyLabelStudioScreen> createState() => _MyLabelStudioScreenState();
}

class _MyLabelStudioScreenState extends State<MyLabelStudioScreen> {
  int _currentNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onStartCreatingLabel() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateLabelDeclarationScreen(),
      ),
    );
  }

  void _onDraftTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening draft: Annapurna Mango Pickle'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _onLabelTap(LabelItemData label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing label: ${label.title}'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _onSampleTap(SampleLabelData sample) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing sample template: ${sample.title}'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    StudioHeader(
                      onNotificationTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notifications'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      onProfileTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Business Profile'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),

                    // Search Bar
                    StudioSearchBar(
                      controller: _searchController,
                      onFilterTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Filters'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Hero Card: Create a new label
                    CreateLabelHeroCard(
                      onStartCreating: _onStartCreatingLabel,
                      onAddTap: _onStartCreatingLabel,
                    ),
                    const SizedBox(height: 24),

                    // Continue Working Section
                    ContinueWorkingSection(
                      onViewDrafts: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening all drafts'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      onDraftCardTap: _onDraftTap,
                    ),
                    const SizedBox(height: 24),

                    // Your Labels Section
                    YourLabelsSection(
                      onSeeAll: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening all labels'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      onLabelTap: _onLabelTap,
                    ),
                    const SizedBox(height: 24),

                    // Get Inspired Carousel
                    GetInspiredSection(onSampleTap: _onSampleTap),
                    const SizedBox(
                      height: 100,
                    ), // Space for floating bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: StudioBottomNav(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
      ),
    );
  }
}
