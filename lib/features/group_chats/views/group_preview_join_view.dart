import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import '../../../core/errors/supabase_error_mapper.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/cached_cloudinary_image.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../cubits/group_profile_cubit/group_profile_cubit.dart';
import '../models/group_profile_model.dart';
import '../models/group_view_args.dart';
import '../widgets/group_square_avatar.dart';

/// Shown to NON-members who open a group (post header, search, repost, deep
/// link, shared URL): cover, avatar, name, description, member count, a
/// "private group" badge and the request-to-join action.
///
/// Requires a [GroupProfileCubit] above it (provided by the router).
class GroupPreviewJoinView extends StatelessWidget {
  final GroupViewArgs args;
  const GroupPreviewJoinView({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GroupProfileCubit, GroupProfileState>(
      listenWhen: (_, cur) => cur is GroupProfileLoaded && cur.profile.isMember,
      listener: (context, state) {
        // Request accepted (realtime) -> unlock: open the full GroupView.
        Navigator.of(
          context,
        ).pushReplacementNamed(AppRoutes.groupViewRoute, arguments: args);
      },
      builder: (context, state) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            foregroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.38),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ),
          body: switch (state) {
            GroupProfileLoaded(:final profile, :final isBusy) => _Content(
              profile: profile,
              isBusy: isBusy,
            ),
            GroupProfileError(:final message) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message),
                  TextButton(
                    onPressed: () => context.read<GroupProfileCubit>().load(),
                    child: Text(context.l10n.retry),
                  ),
                ],
              ),
            ),
            GroupProfileNotFound() => Center(
              child: Text(context.l10n.groupNotFound),
            ),
            _ => const Center(child: CustomLoadingIndicator()),
          },
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  final GroupProfileModel profile;
  final bool isBusy;
  const _Content({required this.profile, required this.isBusy});

  Future<void> _join(BuildContext context) async {
    try {
      await context.read<GroupProfileCubit>().requestToJoin();
    } catch (e) {
      if (context.mounted) {
        final blocked = e.toString().contains('group_blocked');
        AppToast.error(
          blocked
              ? context.l10n.failedToSendRequest
              : SupabaseErrorMapper.toUserMessage(e),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final coverHeight = width / 1.5;
    final hasCover = profile.coverUrl != null && profile.coverUrl!.isNotEmpty;
    final pending = profile.requestStatus == GroupJoinRequestStatus.pending;
    final muted = theme.colorScheme.onSurfaceVariant;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: coverHeight + 46,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: coverHeight,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      hasCover
                          ? CachedCloudinaryImage(
                            secureUrl: profile.coverUrl!,
                            fit: BoxFit.cover,
                            width: width,
                            height: coverHeight,
                          )
                          : DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  theme.primaryColor,
                                  theme.primaryColor.withValues(alpha: 0.5),
                                ],
                              ),
                            ),
                          ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                            stops: const [0, 0.45],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: coverHeight - 46,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.85),
                        width: 2.2,
                      ),
                    ),
                    child: GroupSquareAvatar(
                      url: profile.avatarUrl,
                      size: 92,
                      radius: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text(
                profile.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 23,
                  letterSpacing: context.ls(-0.2),
                ),
              ),
              if (profile.title?.trim().isNotEmpty == true) ...[
                const Gap(4),
                Text(
                  profile.title!.trim(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium!.copyWith(color: muted),
                ),
              ],
              const Gap(12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_rounded, size: 18, color: muted),
                  const Gap(6),
                  Text(
                    context.l10n.membersCountLabel(profile.membersCount),
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: context.ls(0),
                    ),
                  ),
                ],
              ),
              if (profile.description?.trim().isNotEmpty == true) ...[
                const Gap(14),
                Text(
                  profile.description!.trim(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium!.copyWith(height: 1.5),
                ),
              ],
              const Gap(18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.6,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 18, color: muted),
                    const Gap(8),
                    Flexible(
                      child: Text(
                        context.l10n.groupPrivateNotice,
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: muted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: context.ls(0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: (pending || isBusy) ? null : () => _join(context),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    pending ? Icons.schedule_rounded : Icons.group_add_rounded,
                  ),
                  label: Text(
                    pending
                        ? context.l10n.requestSentPending
                        : context.l10n.requestToJoin,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (pending) ...[
                const Gap(10),
                Text(
                  context.l10n.requestPendingReview,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: muted,
                    letterSpacing: context.ls(0),
                  ),
                ),
              ],
              const Gap(40),
            ],
          ),
        ),
      ],
    );
  }
}
