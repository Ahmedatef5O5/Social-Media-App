import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../cubit/story_views_cubit/story_views_cubit.dart';
import 'story_views_bottom_sheet.dart';

class StoryViewsIndicator extends StatelessWidget {
  final VoidCallback onOpen;
  final VoidCallback onClose;

  const StoryViewsIndicator({
    super.key,
    required this.onOpen,
    required this.onClose,
  });

  void _showViewsBottomSheet(BuildContext context) async {
    final viewsCubit = context.read<StoryViewsCubit>();
    onOpen();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (bottomSheetContext) => BlocProvider.value(
            value: viewsCubit,
            child: const StoryViewsBottomSheet(),
          ),
    );

    onClose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoryViewsCubit, StoryViewsState>(
      builder: (context, state) {
        if (state is StoryViewsError) return const SizedBox.shrink();

        final int? count = state is StoryViewsLoaded ? state.viewCount : null;

        return GestureDetector(
          onTap: () => _showViewsBottomSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.remove_red_eye_rounded,
                  color: Colors.white,
                  size: 15,
                ),
                const Gap(6),
                if (count != null)
                  Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
