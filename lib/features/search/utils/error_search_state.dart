import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../posts/cubits/posts_cubit/posts_cubit.dart';

class ErrorSearchState extends StatelessWidget {
  const ErrorSearchState({
    super.key,
    required this.context,
    required this.theme,
    required this.message,
  });

  final BuildContext context;
  final ThemeData theme;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 42,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const Gap(12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const Gap(14),
            TextButton(
              onPressed:
                  () => context.read<PostsCubit>().fetchPosts(isRefresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
