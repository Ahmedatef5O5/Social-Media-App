import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../chats/widgets/empty_placeholder_state.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../cubit/group_details_cubit/group_details_state.dart';
import 'message_builder.dart';

class GroupMessagesList extends StatelessWidget {
  final ItemScrollController scrollController;
  final ItemPositionsListener positionsListener;

  const GroupMessagesList({
    super.key,
    required this.scrollController,
    required this.positionsListener,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupDetailsCubit, GroupDetailsState>(
      builder: (context, state) {
        if (state is GroupDetailsLoading || state is GroupDetailsInitial) {
          return const Center(child: CustomLoadingIndicator());
        }

        if (state is GroupDetailsError) {
          return Center(child: Text(state.message));
        }

        if (state is GroupDetailsLoaded) {
          final messages = state.messages;
          final typing = state.typingUserIds;

          if (messages.isEmpty && typing.isEmpty) {
            return _groupEmptyState(context);
          }

          return ScrollablePositionedList.separated(
            reverse: true,
            itemScrollController: scrollController,
            itemPositionsListener: positionsListener,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: messages.length + (typing.isNotEmpty ? 1 : 0),
            itemBuilder: (_, index) {
              return GroupMessageItemBuilder(
                index: index,
                messages: messages,
                typing: typing,
              );
            },
            separatorBuilder: (_, __) => const Gap(4),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _groupEmptyState(BuildContext context) {
    return EmptyPlaceholderState(
      img: AppImages.blueSmileFaceLot,
      imgHeight: MediaQuery.of(context).size.height * 0.2,
      title: 'No messages yet.',
      style: Theme.of(context).textTheme.titleMedium!.copyWith(
        color: Theme.of(context).primaryColor,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
    );
  }
}
