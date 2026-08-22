import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/skeleton_shapes.dart';
import '../../single_chats/helper/glass_icon_btn.dart';
import '../cubit/ai_chat_sessions_cubit/ai_chat_sessions_cubit.dart';
import '../di/ai_chat_dependencies.dart';
import '../helpers/ai_model_display.dart';
import '../models/ai_chat_session.dart';
import 'syncra_backdrop.dart';

class AiChatSessionsDrawer extends StatelessWidget {
  final AiChatDependencies? deps;
  final String? activeSessionId;
  final VoidCallback onStartNewChat;
  final ValueChanged<AiChatSession> onOpenSession;
  final ValueChanged<AiChatSession> onDeleteSession;

  const AiChatSessionsDrawer({
    super.key,
    required this.deps,
    required this.activeSessionId,
    required this.onStartNewChat,
    required this.onOpenSession,
    required this.onDeleteSession,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: SyncraBackdrop(primary: theme.primaryColor)),
            SafeArea(
              child: Column(
                children: [
                  const _DrawerTopBar(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: _NewChatButton(onTap: onStartNewChat),
                  ),
                  Expanded(child: _buildSessionsList(context)),
                  _buildFooter(context),
                  const Gap(10),
                ],
              ),
            ),
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
          return _SessionsListSection(
            sessions: sessions,
            activeSessionId: activeSessionId,
            onOpenSession: onOpenSession,
            onDeleteSession: onDeleteSession,
          );
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DrawerRow(
            leadingIcon: Icons.tune_rounded,
            leadingColor: Colors.white70,
            title: 'AI Settings',
            isActive: false,
            onTap: () {
              Navigator.of(context).pop(); // close the drawer
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamed(AppRoutes.aiSettingsViewRoute);
            },
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTopBar extends StatelessWidget {
  const _DrawerTopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 4),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
          const Gap(8),
          const Expanded(
            child: Text(
              'Syncra',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.2,
              ),
            ),
          ),
          GlassIconButton(
            icon: Icons.close_rounded,
            size: 36,
            iconSize: 18,
            onTap: () => Navigator.of(context).pop(),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.white.withValues(alpha: 0.10),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 19),
                  Gap(8),
                  Text(
                    'New Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                ],
              ),
            ),
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
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.08),
      highlightColor: Colors.white.withValues(alpha: 0.18),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        itemCount: 8,
        itemBuilder:
            (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: const [
                  SkeletonCircle(size: 34),
                  Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 12, width: 140, radius: 4),
                        Gap(6),
                        SkeletonBox(height: 10, width: 90, radius: 4),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: Colors.white38),
            const Gap(10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionsListSection extends StatefulWidget {
  const _SessionsListSection({
    required this.sessions,
    required this.activeSessionId,
    required this.onOpenSession,
    required this.onDeleteSession,
  });

  final List<AiChatSession> sessions;
  final String? activeSessionId;
  final ValueChanged<AiChatSession> onOpenSession;
  final ValueChanged<AiChatSession> onDeleteSession;

  @override
  State<_SessionsListSection> createState() => _SessionsListSectionState();
}

class _SessionsListSectionState extends State<_SessionsListSection> {
  static const int _pageSize = 15;
  int _visibleCount = _pageSize;

  @override
  Widget build(BuildContext context) {
    final total = widget.sessions.length;
    final visible = widget.sessions.take(_visibleCount).toList();
    final groups = _groupByRecency(visible);
    final hasMore = total > _visibleCount;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      itemCount: groups.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == groups.length) {
          return _LoadMoreTile(
            onTap: () => setState(() => _visibleCount += _pageSize),
          );
        }
        final group = groups[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(label: group.label),
            ...group.sessions.map(
              (session) => _SessionTile(
                session: session,
                isActive: session.id == widget.activeSessionId,
                onTap: () => widget.onOpenSession(session),
                onDelete: () => widget.onDeleteSession(session),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SessionGroup {
  const _SessionGroup(this.label, this.sessions);
  final String label;
  final List<AiChatSession> sessions;
}

/// Buckets by recency the same way ChatGPT/Gemini's own sidebars do —
/// sessions arrive already sorted newest-first (see AiChatRepository),
/// so each bucket stays internally sorted too.
List<_SessionGroup> _groupByRecency(List<AiChatSession> sessions) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final week = today.subtract(const Duration(days: 7));
  final month = today.subtract(const Duration(days: 30));

  final buckets = <String, List<AiChatSession>>{
    'Today': [],
    'Yesterday': [],
    'Previous 7 Days': [],
    'Previous 30 Days': [],
    'Older': [],
  };

  for (final session in sessions) {
    final dt = session.lastMessageAt ?? session.createdAt;
    final day = DateTime(dt.year, dt.month, dt.day);
    if (!day.isBefore(today)) {
      buckets['Today']!.add(session);
    } else if (!day.isBefore(yesterday)) {
      buckets['Yesterday']!.add(session);
    } else if (!day.isBefore(week)) {
      buckets['Previous 7 Days']!.add(session);
    } else if (!day.isBefore(month)) {
      buckets['Previous 30 Days']!.add(session);
    } else {
      buckets['Older']!.add(session);
    }
  }

  return buckets.entries
      .where((e) => e.value.isNotEmpty)
      .map((e) => _SessionGroup(e.key, e.value))
      .toList();
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 6),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Shared visual shell for every row in the Drawer — session tiles, the
/// "Load more" tile, and the "AI Settings" footer row all render through
/// this so the whole surface stays pixel-consistent.
class _DrawerRow extends StatelessWidget {
  const _DrawerRow({
    required this.leadingIcon,
    required this.leadingColor,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.isActive,
    required this.onTap,
  });

  final IconData leadingIcon;
  final Color leadingColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color:
            isActive
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: leadingColor.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(leadingIcon, size: 16, color: leadingColor),
                ),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: isActive ? 1 : 0.92,
                          ),
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const Gap(2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const Gap(6), trailing!],
              ],
            ),
          ),
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
  // notification timestamps elsewhere in the app.
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

  void _showMenu(BuildContext context, Offset globalPosition) {
    showAiSessionActionMenu(
      context: context,
      globalPosition: globalPosition,
      onOpen: onTap,
      onShare: () => _shareSession(context),
      onDelete: onDelete,
    );
  }

  @override
  Widget build(BuildContext context) {
    final display = AiModelDisplay.fromRaw(
      session.activeProvider ?? '',
      session.activeModel ?? '',
    );
    final preview = session.lastMessagePreview?.trim();

    return _DrawerRow(
      leadingIcon: display.icon,
      leadingColor: display.accentColor,
      title: session.title,
      subtitle: preview,
      isActive: isActive,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _relativeTime(session.lastMessageAt ?? session.createdAt),
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          Builder(
            builder: (btnContext) {
              return IconButton(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 16,
                  color: Colors.white54,
                ),
                splashRadius: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                onPressed: () {
                  final renderBox = btnContext.findRenderObject() as RenderBox;
                  final offset = renderBox.localToGlobal(Offset.zero);
                  _showMenu(context, offset);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LoadMoreTile extends StatelessWidget {
  const _LoadMoreTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _DrawerRow(
      leadingIcon: Icons.expand_more_rounded,
      leadingColor: Colors.white54,
      title: 'Load more',
      isActive: false,
      onTap: onTap,
    );
  }
}

class _AiSessionMenuAction {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _AiSessionMenuAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

Future<void> showAiSessionActionMenu({
  required BuildContext context,
  required Offset globalPosition,
  required VoidCallback onOpen,
  required VoidCallback onShare,
  required VoidCallback onDelete,
}) {
  HapticFeedback.mediumImpact();

  final overlay = Overlay.of(context, rootOverlay: true);
  final completer = Completer<void>();
  late OverlayEntry entry;

  void close() {
    if (entry.mounted) entry.remove();
    if (!completer.isCompleted) completer.complete();
  }

  final actions = <_AiSessionMenuAction>[
    _AiSessionMenuAction(
      icon: Icons.chat_bubble_outline_rounded,
      label: 'Open',
      onTap: () {
        close();
        onOpen();
      },
    ),
    _AiSessionMenuAction(
      icon: Icons.share_outlined,
      label: 'Share',
      onTap: () {
        close();
        onShare();
      },
    ),
    _AiSessionMenuAction(
      icon: Icons.delete_outline_rounded,
      label: 'Delete',
      color: Colors.redAccent,
      onTap: () {
        close();
        onDelete();
      },
    ),
  ];

  entry = OverlayEntry(
    builder:
        (context) => _AiSessionActionMenuOverlay(
          anchor: globalPosition,
          actions: actions,
          onDismiss: close,
        ),
  );

  overlay.insert(entry);
  return completer.future;
}

class _AiSessionActionMenuOverlay extends StatefulWidget {
  final Offset anchor;
  final List<_AiSessionMenuAction> actions;
  final VoidCallback onDismiss;

  const _AiSessionActionMenuOverlay({
    required this.anchor,
    required this.actions,
    required this.onDismiss,
  });

  @override
  State<_AiSessionActionMenuOverlay> createState() =>
      _AiSessionActionMenuOverlayState();
}

class _AiSessionActionMenuOverlayState
    extends State<_AiSessionActionMenuOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  );

  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.6, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    const menuWidth = 190.0;
    const verticalPadding = 16.0;
    final menuHeight = 48.0 * widget.actions.length + verticalPadding;

    // ضبط الموضع عشان تظهر القائمة على يسار النقط (3 dots) أو حسب المتاح
    double left = widget.anchor.dx - menuWidth + 30;
    left = left.clamp(12.0, screen.width - menuWidth - 12);

    double top = widget.anchor.dy + 20;
    if (top + menuHeight > screen.height - 24) {
      top = widget.anchor.dy - menuHeight - 12;
    }
    top = top.clamp(24.0, screen.height - menuHeight - 24);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _dismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacity.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: _scale.value,
                  alignment: Alignment.topRight,
                  child: child,
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Builder(
                    // 👈 استخدمنا Builder عشان نجيب الـ Theme
                    builder: (context) {
                      final primary = Theme.of(context).primaryColor;
                      // سحبنا اللون العلوي من الـ Gradient الخاص بالثيم الحالي
                      final topBgColor =
                          SyncraBackdrop.gradientColors(primary).first;

                      return Container(
                        width: menuWidth,
                        decoration: BoxDecoration(
                          // دمج اللون المستخلص مع شفافية عشان التأثير الزجاجي
                          color: topBgColor.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            // بوردر خفيف بلون الـ Primary بتاع الثيم
                            color: primary.withValues(alpha: 0.35),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          // ... (باقي الكود الخاص بالـ actions كما هو بدون تغيير)
                          children: [
                            for (final action in widget.actions)
                              InkWell(
                                onTap: action.onTap,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        action.icon,
                                        size: 20,
                                        color: action.color ?? Colors.white70,
                                      ),
                                      const SizedBox(width: 14),
                                      Text(
                                        action.label,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: action.color ?? Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
