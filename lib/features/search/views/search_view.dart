import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../discover/cubits/discover_people_cubit.dart';
import '../../discover/services/discover_people_services.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../cubits/search_reels_cubit/search_reels_cubit.dart';
import '../cubits/search_posts_cubit/search_posts_cubit.dart';
import '../cubits/search_friends_cubit/search_friends_cubit.dart';
import '../cubits/search_groups_cubit/search_groups_cubit.dart';
import '../../social_graph/cubits/friend_lists_cubit/friends_list_cubit.dart';
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
        BlocProvider(create: (context) => SearchPostsCubit()),
        BlocProvider(
          create: (context) => SearchFriendsCubit(SupabaseProvider.id),
        ),
        BlocProvider(create: (context) => SearchGroupsCubit()),
      ],
      child: const SearchViewBodyWidget(),
    );
  }
}
