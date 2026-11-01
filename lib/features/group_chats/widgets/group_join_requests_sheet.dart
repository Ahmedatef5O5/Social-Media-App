import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import '../../../core/design/components/app_bottom_sheet.dart';
import '../../../core/errors/supabase_error_mapper.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../cubits/group_join_requests_cubit/group_join_requests_cubit.dart';
import '../models/group_join_request_model.dart';

/// Owner/admin sheet listing pending join requests with accept / reject.
class GroupJoinRequestsSheet extends StatelessWidget {
  const GroupJoinRequestsSheet({super.key});

  static Future<void> show(
    BuildContext context, {
    required String groupId,
    VoidCallback? onReviewed,
  }) {
    return AppBottomSheet.show<void>(
      context: context,
      builder:
          (_) => BlocProvider(
            create:
                (_) => GroupJoinRequestsCubit(
                  groupId: groupId,
                  onReviewed: onReviewed,
                )..load(),
            child: const GroupJoinRequestsSheet(),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.75;
    return AppBottomSheet(
      title: context.l10n.pendingRequests,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: BlocBuilder<GroupJoinRequestsCubit, GroupJoinRequestsState>(
          builder: (context, state) {
            if (state is GroupJoinRequestsError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message),
                    TextButton(
                      onPressed:
                          () => context.read<GroupJoinRequestsCubit>().load(),
                      child: Text(context.l10n.retry),
                    ),
                  ],
                ),
              );
            }
            if (state is! GroupJoinRequestsLoaded) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CustomLoadingIndicator()),
              );
            }
            if (state.requests.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text(context.l10n.noPendingRequests)),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: state.requests.length,
              separatorBuilder: (_, __) => const Gap(6),
              itemBuilder:
                  (context, i) => _RequestTile(
                    request: state.requests[i],
                    busy: state.busyIds.contains(state.requests[i].id),
                  ),
            );
          },
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final GroupJoinRequestModel request;
  final bool busy;
  const _RequestTile({required this.request, required this.busy});

  Future<void> _review(BuildContext context, bool accept) async {
    final cubit = context.read<GroupJoinRequestsCubit>();
    try {
      final ok = await cubit.review(request, accept: accept);
      if (ok && context.mounted) {
        AppToast.success(
          accept ? context.l10n.requestAccepted : context.l10n.requestRejected,
        );
      }
    } catch (e) {
      AppToast.error(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        AppAvatar(imageUrl: request.userAvatar, size: 44),
        const Gap(12),
        Expanded(
          child: Text(
            request.userName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall!.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: context.ls(0),
            ),
          ),
        ),
        if (busy)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else ...[
          IconButton.filledTonal(
            tooltip: context.l10n.reject,
            style: IconButton.styleFrom(
              foregroundColor: Colors.red,
              backgroundColor: Colors.red.withValues(alpha: 0.10),
            ),
            onPressed: () => _review(context, false),
            icon: const Icon(Icons.close_rounded),
          ),
          const Gap(4),
          IconButton.filled(
            tooltip: context.l10n.accept,
            onPressed: () => _review(context, true),
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ],
    );
  }
}
