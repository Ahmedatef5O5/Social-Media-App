import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/themes/cubits/theme_cubit.dart';
import '../../../core/themes/models/app_theme_model.dart';
import '../widgets/settings_detail_sliver_app_bar.dart';
import '../widgets/theme_selection_tile.dart';

class ThemesSelectView extends StatelessWidget {
  final String userId;

  const ThemesSelectView({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              const SettingsDetailSliverAppBar(
                icon: Icons.palette_rounded,
                title: 'Appearance',
                subtitle:
                    'Pick a look that feels like you. Changes apply instantly.',
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = AppThemeModel.themes[index];
                    final isSelected = state.theme.type == item.type;

                    return ThemeSelectionTile(
                      item: item,
                      isSelected: isSelected,
                      onTap: () {
                        context.read<ThemeCubit>().changeTheme(item, userId);
                      },
                    );
                  }, childCount: AppThemeModel.themes.length),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
