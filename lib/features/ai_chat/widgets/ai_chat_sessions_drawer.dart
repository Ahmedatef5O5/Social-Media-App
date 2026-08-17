import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/skeleton_shapes.dart';
import '../../ai_assistant/widgets/ai_usage_quota_card.dart';
import '../../settings/widgets/drawer_item_widget.dart';
import '../cubit/ai_chat_sessions_cubit/ai_chat_sessions_cubit.dart';
import '../di/ai_chat_dependencies.dart';
import '../models/ai_chat_session.dart';
import '../models/ai_model_option.dart';
import 'ai_model_selector.dart';

class AiChatSessionsDrawer extends StatelessWidget {
  final AiChatDependencies? deps;
  final String? activeSessionId;
  final AiModelOption selectedModel;
  final ValueChanged<AiModelOption> onModelChanged;
  final VoidCallback onStartNewChat;
  final ValueChanged<AiChatSession> onOpenSession;
  final ValueChanged<AiChatSession> onDeleteSession;

  const AiChatSessionsDrawer({
    super.key,
    required this.deps,
    required this.activeSessionId,
    required this.selectedModel,
    required this.onModelChanged,
    required this.onStartNewChat,
    required this.onOpenSession,
    required this.onDeleteSession,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _DrawerTopBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _NewChatButton(onTap: onStartNewChat),
            ),
            const Divider(height: 1, indent: 20, endIndent: 20),
            Expanded(child: _buildSessionsList(context)),
            const Divider(height: 1, indent: 20, endIndent: 20),
            _buildFooter(context),
            const Gap(8),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsList(BuildContext context) {
    final deps = this.deps;
    if (deps == null) return const _SessionsShimmer();

    return BlocProvider.value(
      value: deps.sessionsCubit,
      child: BlocBuilder<AiChatSessionsCubit, AiChatSessionsState>(
        builder: (context, state) {
          if (state is AiChatSessionsLoading) return const _SessionsShimmer();
          if (state is AiChatSessionsError) {
            return const _SessionsMessage(
              icon: Icons.cloud_off_rounded,
              text: "Couldn't load your conversations.",
            );
          }
          final sessions = (state as AiChatSessionsLoaded).sessions;
          if (sessions.isEmpty) {
            return const _SessionsMessage(
              icon: Icons.forum_outlined,
              text: 'No conversations yet — start one above.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _SessionTile(
                session: session,
                isActive: session.id == activeSessionId,
                onTap: () => onOpenSession(session),
                onDelete: () => onDeleteSession(session),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DrawerItemWidget(
          icon: Icons.tune_rounded,
          title: 'AI Settings',
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(
              context,
              rootNavigator: true,
            ).pushNamed(AppRoutes.aiSettingsViewRoute);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: _CurrentModelRow(
            selected: selectedModel,
            onChanged: onModelChanged,
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: AiUsageQuotaCard(),
        ),
      ],
    );
  }
}

class _DrawerTopBar extends StatelessWidget {
  const _DrawerTopBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: theme.primaryColor, size: 20),
          const Gap(8),
          const Expanded(
            child: Text(
              'Syncra',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _NewChatButton extends StatelessWidget {
  const _NewChatButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.primaryColor.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_comment_rounded,
                color: theme.primaryColor,
                size: 18,
              ),
              const Gap(8),
              Text(
                'New Chat',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionsShimmer extends StatelessWidget {
  const _SessionsShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        itemCount: 6,
        itemBuilder:
            (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: const [
                  SkeletonCircle(size: 38),
                  Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 13, width: 140, radius: 4),
                        Gap(6),
                        SkeletonBox(height: 11, width: 90, radius: 4),
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

class _SessionsMessage extends StatelessWidget {
  const _SessionsMessage({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white38 : Colors.grey.shade500;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            const Gap(10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  final AiChatSession session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  // Same "now / Xm / Xh / Xd / d/m" convention already used for
  // notification timestamps elsewhere in the app — no shared time-utils
  // file exists to import, each screen defines its own.
  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  Future<void> _shareSession(BuildContext context) async {
    final preview = session.lastMessagePreview?.trim();
    final shareText = [
      session.title,
      if (preview != null && preview.isNotEmpty) preview,
    ].join('\n');
    try {
      await SharePlus.instance.share(
        ShareParams(text: shareText, subject: session.title),
      );
    } catch (_) {
      if (context.mounted) {
        AppToast.error('Failed to share this chat. Please try again.');
      }
    }
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline_rounded),
                  title: const Text('Open'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onTap();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('Share'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareSession(context);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                  title: Text(
                    'Delete',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onDelete();
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final preview = session.lastMessagePreview?.trim();
    final mutedColor = isDark ? Colors.white54 : Colors.grey.shade600;
    final faintColor = isDark ? Colors.white38 : Colors.grey.shade500;

    return Material(
      color:
          isActive
              ? theme.primaryColor.withValues(alpha: isDark ? 0.14 : 0.08)
              : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.forum_rounded,
                  size: 17,
                  color: theme.primaryColor,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (preview != null && preview.isNotEmpty) ...[
                      const Gap(2),
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: mutedColor),
                      ),
                    ],
                  ],
                ),
              ),
              const Gap(6),
              Text(
                _relativeTime(session.lastMessageAt ?? session.createdAt),
                style: TextStyle(fontSize: 11, color: faintColor),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 18),
                splashRadius: 18,
                onPressed: () => _showMenu(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentModelRow extends StatelessWidget {
  const _CurrentModelRow({required this.selected, required this.onChanged});
  final AiModelOption selected;
  final ValueChanged<AiModelOption> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = isDark ? Colors.white54 : Colors.grey.shade600;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap:
          () => AiModelSelector.openPicker(
            context,
            selected: selected,
            onChanged: onChanged,
          ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(selected.icon, color: selected.accentColor, size: 22),
            const Gap(16),
            const Expanded(
              child: Text(
                'Current Model',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
            ),
            Text(
              selected.name,
              style: TextStyle(
                color: mutedColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const Gap(4),
            Icon(Icons.arrow_forward_ios, size: 14, color: mutedColor),
          ],
        ),
      ),
    );
  }
}
