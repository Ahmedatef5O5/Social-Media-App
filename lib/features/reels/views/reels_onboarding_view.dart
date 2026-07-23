import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import '../model/reel_category.dart';
import '../services/reels_preferences_store.dart';

class ReelsOnboardingView extends StatefulWidget {
  const ReelsOnboardingView({super.key});

  @override
  State<ReelsOnboardingView> createState() => _ReelsOnboardingViewState();
}

class _ReelsOnboardingViewState extends State<ReelsOnboardingView> {
  final Set<String> _selected = {};
  bool _isSaving = false;

  void _toggle(String value) {
    setState(() {
      _selected.contains(value)
          ? _selected.remove(value)
          : _selected.add(value);
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isSaving ? null : () => _finish(skipped: true),
                  child: Text(
                    'Skip now',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: .65),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.primaryColor,
                size: 52,
              ),
              const SizedBox(height: 20),
              Text(
                'What do you like to watch?',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Choose the sections that interest you so we can customize the reels to your liking',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: .7,
                    ),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: ReelCategories.all.length,
                  itemBuilder: (context, index) {
                    final category = ReelCategories.all[index];
                    return _CategoryTile(
                      category: category,
                      isSelected: _selected.contains(category.value),
                      onTap: () => _toggle(category.value),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: CustomElevatedButton(
                  txtBtn:
                      _selected.isEmpty
                          ? 'Done'
                          : 'Done (${_selected.length} selected)',
                  isLoading: _isSaving,
                  bgColor: AppColors.primaryColor,
                  onPressed: () => _finish(skipped: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ReelCategoryOption category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color:
              isSelected
                  ? AppColors.primaryColor.withValues(alpha: .15)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: .45),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.primaryColor
                    : colorScheme.outline.withValues(alpha: .4),
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    color:
                        isSelected
                            ? AppColors.primaryColor
                            : colorScheme.onSurfaceVariant,
                    size: 30,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.label,
                    style: TextStyle(
                      color:
                          isSelected
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primaryColor,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
