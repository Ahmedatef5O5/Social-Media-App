import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/chat_shared/helpers/avatar_stack.dart';
import '../../../core/router/app_routes.dart';
import '../cubits/comments_cubit.dart';
import '../models/comment_typing_user.dart';

class CommentTypingRow extends StatelessWidget {
  final List<CommentTypingUser> typingUsers;

  const CommentTypingRow({super.key, required this.typingUsers});

  void _openProfile(BuildContext context, String userId) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed(AppRoutes.profileViewRoute, arguments: userId);
  }

  String _joinedNamesLabel() {
    if (typingUsers.length == 1) return typingUsers.first.name;
    if (typingUsers.length == 2) {
      return '${typingUsers[0].name} and ${typingUsers[1].name}';
    }
    return '${typingUsers[0].name} and ${typingUsers.length - 1} others';
  }

  @override
  Widget build(BuildContext context) {
    if (typingUsers.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    final bool isSingle = typingUsers.length == 1;
    final String actionText =
        isSingle ? ' is writing a comment...' : ' are writing a comment...';

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: theme.primaryColor.withValues(alpha: 0.1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.asset(
                AppImages.newCommentIcon,
                color: theme.primaryColor,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        AvatarStack(
          imageUrls: typingUsers.map((u) => u.imageUrl ?? '').toList(),
          avatarSize: 20,
          overlapOffset: 14,
          maxVisible: 3,
        ),
        const SizedBox(width: 5),

        Expanded(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                fontStyle: FontStyle.italic,
              ),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap:
                        typingUsers.length == 1
                            ? () => _openProfile(context, typingUsers.first.id)
                            : null,
                    child: Text(
                      _joinedNamesLabel(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ),
                ),
                TextSpan(text: actionText),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AnchoredCommentTypingRow extends StatefulWidget {
  const AnchoredCommentTypingRow({super.key});

  @override
  State<AnchoredCommentTypingRow> createState() =>
      _AnchoredCommentTypingRowState();
}

class _AnchoredCommentTypingRowState extends State<AnchoredCommentTypingRow> {
  List<CommentTypingUser> _displayUsers = const [];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommentsCubit, CommentsState>(
      buildWhen:
          (previous, current) =>
              current is CommentTypingUsersChanged ||
              current is CommentsUiChanged,
      builder: (context, state) {
        final cubit = context.read<CommentsCubit>();
        final typingUsers = cubit.typingUsersById.values.toList();
        final bool isVisible = typingUsers.isNotEmpty && cubit.isNearEdge;

        if (typingUsers.isNotEmpty) _displayUsers = typingUsers;

        return IgnorePointer(
          ignoring: !isVisible,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isVisible ? 1 : 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              offset: isVisible ? Offset.zero : const Offset(0, 0.4),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ).copyWith(bottom: 8),
                child: CommentTypingRow(typingUsers: _displayUsers),
              ),
            ),
          ),
        );
      },
    );
  }
}

class InlineCommentTypingRow extends StatefulWidget {
  final EdgeInsetsGeometry? padding;

  const InlineCommentTypingRow({super.key, this.padding});

  @override
  State<InlineCommentTypingRow> createState() => _InlineCommentTypingRowState();
}

class _InlineCommentTypingRowState extends State<InlineCommentTypingRow> {
  List<CommentTypingUser> _displayUsers = const [];

  static const double _rowHeight = 22;
  static const double _bottomGap = 4;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommentsCubit, CommentsState>(
      buildWhen:
          (previous, current) =>
              current is CommentTypingUsersChanged ||
              current is CommentsUiChanged,
      builder: (context, state) {
        final cubit = context.read<CommentsCubit>();
        final typingUsers = cubit.typingUsersById.values.toList();
        final bool isVisible = typingUsers.isNotEmpty && cubit.isNearEdge;

        if (typingUsers.isNotEmpty) _displayUsers = typingUsers;

        return SizedBox(
          height: _rowHeight + _bottomGap,
          child: IgnorePointer(
            ignoring: !isVisible,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isVisible ? 1 : 0,
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: widget.padding ?? EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: _bottomGap),
                    child: CommentTypingRow(typingUsers: _displayUsers),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
