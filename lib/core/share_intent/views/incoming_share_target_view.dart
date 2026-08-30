import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../../features/ai_chat/views/ai_chat_view.dart';
import '../../../features/home/cubits/home_cubit/home_cubit.dart';
import '../../../features/posts/cubits/posts_cubit/posts_cubit.dart';
import '../../../features/stories/cubits/stories_cubit/stories_cubit.dart';
import '../../chat_shared/cubits/conversations_cubit/conversations_cubit.dart';
import '../../chat_shared/models/conversation_item.dart';
import '../../constants/app_images.dart';
import '../../router/app_routes.dart';
import '../../toast/app_toast.dart';
import '../../widgets/custom_loading_indicator.dart';
import '../models/incoming_share_payload.dart';
import '../widgets/incoming_share_sliver_app_bar.dart';
import '../widgets/modern_share_tile.dart';
import '../widgets/recent_chat_tile.dart';

class IncomingShareTargetView extends StatelessWidget {
  final IncomingSharePayload payload;
  const IncomingShareTargetView({super.key, required this.payload});

  bool get _aiSupportsPayload =>
      payload.kind != IncomingShareKind.video &&
      payload.kind != IncomingShareKind.unsupported;

  void _safeNavigate(
    BuildContext context,
    String label,
    void Function() action,
  ) {
    try {
      action();
    } catch (e) {
      debugPrint('⚠️ IncomingShareTargetView: $label routing failed: $e');
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.homeRoute, (route) => false);
    }
  }

  void _onStoryTap(BuildContext context) => _safeNavigate(context, 'Story', () {
    final storiesCubit = context.read<StoriesCubit>();
    final currentUser = context.read<HomeCubit>().currentUserData;
    if (currentUser == null) {
      AppToast.error('Your profile is still loading — try again in a second.');
      return;
    }
    switch (payload.kind) {
      case IncomingShareKind.text:
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.createTextStoryViewRoute,
          arguments: {
            'storiesCubit': storiesCubit,
            'currentUser': currentUser,
            'initialText': payload.text,
          },
        );
        break;
      case IncomingShareKind.image:
      case IncomingShareKind.video:
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.addStoryPreviewViewRoute,
          arguments: {
            'file': File(payload.files.first.path),
            'isVideo': payload.kind == IncomingShareKind.video,
            'storiesCubit': storiesCubit,
            'currentUser': currentUser,
          },
        );
        break;
      case IncomingShareKind.document:
      case IncomingShareKind.unsupported:
        AppToast.info("Stories don't support documents yet.");
    }
  });

  void _onPostTap(BuildContext context) => _safeNavigate(context, 'Post', () {
    final postsCubit = context.read<PostsCubit>();
    switch (payload.kind) {
      case IncomingShareKind.image:
        postsCubit.attachExternalMedia(image: XFile(payload.files.first.path));
        break;
      case IncomingShareKind.video:
        postsCubit.attachExternalMedia(video: XFile(payload.files.first.path));
        break;
      case IncomingShareKind.document:
        postsCubit.attachExternalMedia(
          document: XFile(payload.files.first.path),
        );
        break;
      case IncomingShareKind.text:
      case IncomingShareKind.unsupported:
        break;
    }
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.createPostViewRoute,
      arguments: {
        'cubit': postsCubit,
        'initialText': payload.isText ? payload.text : null,
      },
    );
  });

  void _onAiTap(BuildContext context) {
    if (!_aiSupportsPayload) {
      AppToast.info("AI doesn't support video yet");
      return;
    }
    _safeNavigate(context, 'AI', () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) {
            if (payload.isText) {
              return AiChatView(initialDraftText: payload.text);
            }
            final path = payload.files.first.path;
            if (payload.kind == IncomingShareKind.image) {
              return AiChatView(initialDraftImageLocalPath: path);
            }
            // document: pdf / txt / etc.
            return AiChatView(
              initialDraftFileLocalPath: path,
              initialDraftFileName: path.split('/').last,
            );
          },
        ),
      );
    });
  }

  void _onChatTap(BuildContext context, ConversationItem item) =>
      _safeNavigate(context, 'Chat', () {
        if (item.kind == ConversationKind.group) {
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.groupChatRoute,
            arguments: {'group': item.group, 'incomingShare': payload},
          );
        } else {
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.chatDetailsViewRoute,
            arguments: {'user': item.chat, 'incomingShare': payload},
          );
        }
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPopNormally = Navigator.canPop(context);

    return PopScope(
      canPop: canPopNormally,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.homeRoute, (route) => false);
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: BlocBuilder<ConversationsCubit, ConversationsState>(
          builder: (context, state) {
            return CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                IncomingShareSliverAppBar(
                  theme: theme,
                  canPopNormally: canPopNormally,
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      ModernShareTile(
                        title: 'Share to Story',
                        leading: Image.asset(
                          AppImages.storyIcon,
                          width: 26,
                          height: 26,
                          color: const Color(0xFFFF6B6B),
                        ),
                        bgColor: const Color(
                          0xFFFF6B6B,
                        ).withValues(alpha: 0.12),
                        onTap: () => _onStoryTap(context),
                      ),
                      ModernShareTile(
                        title: 'Create Post',
                        leading: const Icon(
                          Icons.dynamic_feed_rounded,
                          color: Color(0xFF4CAF50),
                          size: 26,
                        ),
                        bgColor: const Color(
                          0xFF4CAF50,
                        ).withValues(alpha: 0.12),
                        onTap: () => _onPostTap(context),
                      ),
                      ModernShareTile(
                        title: 'Ask Syncra AI',

                        leading: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFF9C27B0),
                          size: 26,
                        ),
                        bgColor: const Color(
                          0xFF9C27B0,
                        ).withValues(alpha: 0.12),
                        enabled: _aiSupportsPayload,
                        subtitle:
                            _aiSupportsPayload
                                ? null
                                : "AI doesn't support video yet",
                        onTap: () => _onAiTap(context),
                      ),
                    ]),
                  ),
                ),

                if (state is ConversationsLoaded && state.items.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 5, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Recent Chats',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${state.items.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => RecentChatTile(
                          item: state.items[index],
                          onTap: () => _onChatTap(context, state.items[index]),
                        ),
                        childCount: state.items.length,
                      ),
                    ),
                  ),
                ] else if (state is! ConversationsLoaded) ...[
                  const SliverFillRemaining(
                    child: Center(child: CustomLoadingIndicator()),
                  ),
                ] else ...[
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No conversations yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            );
          },
        ),
      ),
    );
  }
}
