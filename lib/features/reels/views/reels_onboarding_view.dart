import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import '../models/reel_category.dart';
import '../services/reels_preferences_store.dart';
import '../widgets/category_tile.dart';

class ReelsOnboardingView extends StatefulWidget {
  const ReelsOnboardingView({super.key});

  @override
  State<ReelsOnboardingView> createState() => _ReelsOnboardingViewState();
}

class _ReelsOnboardingViewState extends State<ReelsOnboardingView> {
  final Set<String> _selected = {};
  bool _isSaving = false;

  void _toggle(String value) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selected.contains(value)) {
        _selected.remove(value);
      } else {
        _selected.add(value);
      }
    });
  }

  Future<void> _finish({required bool skipped}) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final categories = skipped ? <String>[] : _selected.toList();
    await ReelsPreferencesStore.instance.savePreferences(
      categories: categories,
    );

    if (!mounted) return;
    Navigator.of(context).pop<List<String>>(categories);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryColor.withValues(
                                    alpha: 0.08,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryColor.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 30,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: AppColors.primaryColor,
                                  size: 42,
                                ),
                              ),
                              const SizedBox(height: 28),

                              Text(
                                'What do you like?',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                ),
                                child: Text(
                                  'Choose the topics that interest you so we can personalize your reels experience.',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.55,
                                    ),
                                    fontSize: 14.5,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 36),
                            ],
                          ),
                        ),

                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 18,
                                  crossAxisSpacing: 18,
                                  childAspectRatio: 1.25,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final category = ReelCategories.all[index];
                              return CategoryTile(
                                category: category,
                                isSelected: _selected.contains(category.value),
                                onTap: () => _toggle(category.value),
                              );
                            }, childCount: ReelCategories.all.length),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 60)),
                      ],
                    ),

                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colorScheme.surface.withValues(alpha: 0.0),
                              colorScheme.surface.withValues(alpha: 0.8),
                              colorScheme.surface,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                color: colorScheme.surface,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed:
                          _isSaving ? null : () => _finish(skipped: true),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                        splashFactory: NoSplash.splashFactory,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    CustomElevatedButton(
                      txtBtn:
                          _selected.isEmpty
                              ? 'Done'
                              : 'Done (${_selected.length} selected)',
                      isLoading: _isSaving,
                      bgColor: AppColors.primaryColor,
                      onPressed: () => _finish(skipped: false),
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
