import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../discover/cubit/discover_people_cubit.dart';
import '../../discover/services/discover_people_services.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../cubit/search_reels_cubit/search_reels_cubit.dart';
import '../../social_graph/cubit/friend_lists_cubit/friends_list_cubit.dart';
import '../../social_graph/services/follow_services.dart';
import '../../social_graph/services/friendship_services.dart';
import '../widgets/search_view_body_widget.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create:
              (context) => DiscoverPeopleCubit(
                context.read<DiscoverPeopleServices>(),
                friendshipServices: context.read<FriendshipServices>(),
                followServices: context.read<FollowServices>(),
                homeCubit: context.read<HomeCubit>(),
              )..getDiscoverPeople(),
        ),
        BlocProvider(
          create:
              (context) => FriendsListCubit(
                context.read<FriendshipServices>(),
                userId: SupabaseProvider.id,
              )..loadFriends(),
        ),
        BlocProvider(create: (context) => SearchReelsCubit()..getReels()),
      ],
      child: const SearchViewBodyWidget(),
    );
  }
}
