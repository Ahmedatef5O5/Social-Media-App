import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/chats/widgets/chats_list_view_section.dart';
import '../../../core/router/app_router.dart';
import '../cubit/chats_cubit/chats_cubit.dart';

class ChatsViewBody extends StatefulWidget {
  const ChatsViewBody({super.key});

  @override
  State<ChatsViewBody> createState() => _ChatsViewBodyState();
}

class _ChatsViewBodyState extends State<ChatsViewBody>
    with WidgetsBindingObserver, RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ChatsCubit>().getChats(isRefresh: true);
    }
  }

  @override
  void didPopNext() {
    debugPrint('Return to Chats List... updating automatically');
    context.read<ChatsCubit>().getChats(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatsCubit, ChatsState>(
              buildWhen: (prev, curr) {
                return curr is ChatsSuccessloaded ||
                    curr is ChatsLoading ||
                    curr is ChatsError ||
                    curr is ChatsInitial;
              },
              builder: (context, state) {
                if (state is ChatsSuccessloaded) {
                  return ChatsListViewSection(chats: state.chats);
                }

                if (state is ChatsLoading || state is ChatsInitial) {
                  return const CustomLoadingIndicator();
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
