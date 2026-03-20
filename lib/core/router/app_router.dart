import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/views/loading_screen.dart';
import 'package:social_media_app/core/views/no_route_screen.dart';
import 'package:social_media_app/core/widgets/custom_bottom_nav_bar.dart';
import 'package:social_media_app/features/auth/views/auth_view.dart';
import 'package:social_media_app/features/chats/cubit/chat_details_cubit/chat_details_cubit.dart';
import 'package:social_media_app/features/chats/models/chat_user_model.dart';
import 'package:social_media_app/features/chats/services/chat_services.dart';
import 'package:social_media_app/features/chats/views/chat_details_view.dart';
import 'package:social_media_app/features/chats/views/chats_view.dart';
import 'package:social_media_app/features/discover/cubit/discover_people_cubit.dart';
import 'package:social_media_app/features/discover/services/discover_people_services.dart';
import 'package:social_media_app/features/home/cubit/home_cubit.dart';
import 'package:social_media_app/features/home/models/story_model.dart';
import 'package:social_media_app/features/home/views/create_post_view.dart';
import 'package:social_media_app/features/home/views/post_themes_view.dart';
import 'package:social_media_app/features/home/views/story_display_view.dart';
import 'package:social_media_app/features/profile/cubits/edit_profile_cubit/edit_profile_cubit.dart';
import 'package:social_media_app/features/profile/services/edit_profile_services.dart';
import 'package:social_media_app/features/profile/views/edit_profile_view.dart';
import 'package:social_media_app/features/settings/views/settings_view.dart';
import 'package:social_media_app/features/splash/views/on_boarding_view.dart';
import 'package:social_media_app/features/splash/views/splash_view.dart';
import '../../features/auth/data/models/user_data.dart';
import '../../features/chats/cubit/chats_cubit/chats_cubit.dart';
import '../../features/home/views/creat_text_story_view.dart';

class AppRouter {
  static bool _isAuthCallback(String? routeName) {
    if (routeName == null) return false;
    return routeName.startsWith('/?') ||
        routeName.contains('code=') ||
        routeName.contains('#_=_') ||
        routeName.contains(AppRoutes.loginCallback);
  }

  static Route<dynamic> _buildRoute(Widget child, {RouteSettings? settings}) =>
      CupertinoPageRoute(builder: (_) => child, settings: settings);

  static Route<dynamic> generateRoute(RouteSettings settings) {
    if (_isAuthCallback(settings.name)) {
      return _buildRoute(const LoadingScreen());
    }
    switch (settings.name) {
      case AppRoutes.splashViewRoute:
        return _buildRoute(const SplashView(), settings: settings);

      case AppRoutes.onBoardingViewRoute:
        return _buildRoute(const OnBoardingView(), settings: settings);

      case AppRoutes.authRoute:
        return _buildRoute(const AuthView(), settings: settings);

      case AppRoutes.homeRoute:
        return _buildRoute(
          MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => HomeCubit()..getHomeData()),
              BlocProvider(
                create:
                    (context) =>
                        DiscoverPeopleCubit(DiscoverPeopleServices())
                          ..getDiscoverPeople(),
              ),
              BlocProvider(create: (context) => ChatsCubit()..getChats()),
            ],
            child: const CustomBottomNavBar(),
          ),
          settings: settings,
        );
      case AppRoutes.chatsViewRoute:
        return _buildRoute(const ChatsView(), settings: settings);

      case AppRoutes.chatDetailsViewRoute:
        final user = settings.arguments as ChatUserModel;
        return _buildRoute(
          BlocProvider(
            create:
                (context) =>
                    ChatDetailsCubit(ChatServices())
                      ..getMessagesStream(receiverId: user.id),
            child: ChatDetailsView(receiverUser: user),
          ),
          settings: settings,
        );

      case AppRoutes.storyDisplayViewRoute:
        final story = settings.arguments as StoryModel;
        return _buildRoute(StoryDisplayView(story: story), settings: settings);

      case AppRoutes.createTextStoryViewRoute:
        final cubit = settings.arguments as HomeCubit;
        return _buildRoute(
          BlocProvider.value(value: cubit, child: const CreateTextStoryView()),
          settings: settings,
        );
      case AppRoutes.createPostViewRoute:
        return _buildRoute(
          BlocProvider.value(
            value: settings.arguments as HomeCubit,
            child: const CreatePostView(),
          ),
          settings: settings,
        );

      case AppRoutes.postThemesViewRoute:
        return _buildRoute(const PostThemesView(), settings: settings);

      case AppRoutes.editProfileViewRoute:
        final user = settings.arguments as UserData;
        return _buildRoute(
          BlocProvider(
            create: (context) => EditProfileCubit(EditProfileServices()),
            child: EditProfileView(userData: user),
          ),
          settings: settings,
        );
      case AppRoutes.settingsViewRoute:
        return _buildRoute(SettingsView(), settings: settings);

      default:
        return _buildRoute(NoRouteScreen(routeName: settings.name));
    }
  }
}
