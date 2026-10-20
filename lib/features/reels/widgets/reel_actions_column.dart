import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/toast/app_toast.dart';
import '../../posts/cubits/posts_cubit/posts_cubit.dart';
import '../models/reel_model.dart';
import '../utils/action_button.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class ReelActionsColumn extends StatefulWidget {
  final ReelModel reel;
  const ReelActionsColumn({super.key, required this.reel});

  @override
  State<ReelActionsColumn> createState() => _ReelActionsColumnState();
}

class _ReelActionsColumnState extends State<ReelActionsColumn> {
  bool _likedLocally = false;

  bool _isSharing = false;
  bool _isCopyingLink = false;

  Future<void> _toggleReshare(bool isCurrentlyShared) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    final postsCubit = context.read<PostsCubit>();
    final currentUserId = SupabaseProvider.idOrNull;

    if (isCurrentlyShared) {
      final state = postsCubit.state;
      if (state is PostsLoaded && currentUserId != null) {
        final wrapperPosts =
            state.posts
                .where(
                  (p) =>
                      p.authorId == currentUserId &&
                      p.sharedReelId == widget.reel.id,
                )
                .toList();

        if (wrapperPosts.isNotEmpty) {
          await postsCubit.deletePost(wrapperPosts.first.id);
          AppToast.info(context.l10n.shareRemoved);
        }
      }
    } else {
      final success = await postsCubit.shareReel(widget.reel);
      if (success) {
        AppToast.success(context.l10n.reelSharedToYour);
      } else {
        AppToast.error(context.l10n.couldNotShareThis);
      }
    }

    if (!mounted) return;
    setState(() => _isSharing = false);
  }

  Future<void> _copyLink() async {
    if (_isCopyingLink) return;
    setState(() => _isCopyingLink = true);

    final link = widget.reel.youtubeWatchUrl;

    try {
      await Clipboard.setData(ClipboardData(text: link));
      if (!mounted) return;
      AppToast.success(context.l10n.linkCopiedToClipboard);

      await SharePlus.instance.share(
        ShareParams(text: link, subject: widget.reel.title),
      );
    } catch (e) {
      debugPrint('Error sharing reel link: $e');
      if (mounted) {
        AppToast.error(context.l10n.couldNotShareThis2);
      }
    } finally {
      if (mounted) setState(() => _isCopyingLink = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedLikes =
        widget.reel.originalLikeCount + (_likedLocally ? 1 : 0);
    final postsState = context.watch<PostsCubit>().state;
    final currentUserId = SupabaseProvider.idOrNull;

    bool isSharedByMe = false;
    if (postsState is PostsLoaded && currentUserId != null) {
      isSharedByMe = postsState.posts.any(
        (p) => p.authorId == currentUserId && p.sharedReelId == widget.reel.id,
      );
    }

    return Column(
      children: [
        ActionButton(
          icon: _likedLocally ? Icons.favorite : Icons.favorite_border,
          iconColor: _likedLocally ? Colors.red : Colors.white,
          label: _formatCount(displayedLikes),
          onTap: () => setState(() => _likedLocally = !_likedLocally),
        ),
        const SizedBox(height: 20),
        ActionButton(
          icon: Icons.repeat_rounded,
          iconColor:
              isSharedByMe ? Theme.of(context).primaryColor : Colors.white,
          label: context.l10n.reshare,
          onTap: () => _toggleReshare(isSharedByMe),
        ),

        const SizedBox(height: 20),
        ActionButton(
          icon: Icons.link_rounded,
          label: context.l10n.copyLink,
          onTap: _copyLink,
        ),
        const SizedBox(height: 20),
        ActionButton(
          icon: Icons.remove_red_eye_outlined,
          label: _formatCount(widget.reel.originalViewCount),
          onTap: () {},
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}
