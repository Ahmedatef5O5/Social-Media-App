import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
import 'package:social_media_app/features/home/services/home_services.dart';
import 'package:social_media_app/features/home/views/create_post_view.dart';
import 'package:social_media_app/features/home/views/post_themes_view.dart';
import 'package:social_media_app/features/home/views/story_display_view.dart';
import 'package:social_media_app/features/home/widgets/full_screen_image_viewer.dart';
import 'package:social_media_app/features/profile/cubits/edit_profile_cubit/edit_profile_cubit.dart';
import 'package:social_media_app/features/profile/services/edit_profile_services.dart';
import 'package:social_media_app/features/profile/views/edit_profile_view.dart';
import 'package:social_media_app/features/settings/views/settings_view.dart';
import 'package:social_media_app/features/splash/views/on_boarding_view.dart';
import 'package:social_media_app/features/splash/views/splash_view.dart';
import '../../features/auth/data/models/user_data.dart';
import '../../features/chats/cubit/chats_cubit/chats_cubit.dart';
import '../../features/group_chat/models/group_model.dart';
import '../../features/group_chat/views/group_chat_view.dart';
import '../../features/home/views/add_story_caption_view.dart';
import '../../features/home/views/creat_text_story_view.dart';
import '../../features/profile/cubits/profile_cubit/profile_cubit.dart';
import '../../features/profile/views/profile_view.dart';

enum TypeOfRoute { material, cupertino, fade }

class AppRouter {
  static bool _isAuthCallback(String? routeName) {
    if (routeName == null) return false;
    return routeName.startsWith('/?') ||
        routeName.contains('code=') ||
        routeName.contains('#_=_') ||
        routeName.contains(AppRoutes.loginCallback);
  }

  static Route<dynamic> _buildRoute(
    Widget child, {
    RouteSettings? settings,
    TypeOfRoute? typeOfRoute,
  }) {
    final routeType = typeOfRoute ?? TypeOfRoute.cupertino;
    switch (routeType) {
      case TypeOfRoute.fade:
        return PageRouteBuilder(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        );

      case TypeOfRoute.material:
        return MaterialPageRoute(builder: (_) => child, settings: settings);

      default:
        return CupertinoPageRoute(builder: (_) => child, settings: settings);
    }
  }

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
              BlocProvider(
                create: (context) => ChatsCubit(ChatServices())..monitorChats(),
              ),
            ],
            child: const CustomBottomNavBar(),
          ),
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

      case AppRoutes.fullScreenImageViewRoute:
        return _buildRoute(
          FullScreenImageViewer(),
          typeOfRoute: TypeOfRoute.fade,
          settings: settings,
        );

      case AppRoutes.createTextStoryViewRoute:
        final cubit = settings.arguments as HomeCubit;
        return _buildRoute(
          BlocProvider.value(value: cubit, child: const CreateTextStoryView()),
          settings: settings,
        );
      case AppRoutes.addStoryCaptionViewRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          AddStoryCaptionView(
            file: args['file'] as File,
            homeCubit: args['homeCubit'] as HomeCubit,
          ),
          settings: settings,
        );
      case AppRoutes.storyDisplayViewRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          StoryDisplayView(
            homeCubit: args['homeCubit'],
            allUserGroups: args['allUserGroups'],
            initialGroupIndex: args['initialGroupIndex'],
          ),
          typeOfRoute: TypeOfRoute.fade,
          settings: settings,
        );

      case AppRoutes.chatsViewRoute:
        return _buildRoute(const ChatsView(), settings: settings);

      case AppRoutes.chatDetailsViewRoute:
        final user = settings.arguments as ChatUserModel;
        return _buildRoute(
          BlocProvider(
            create: (context) => ChatDetailsCubit(ChatServices(), user.name),
            child: ChatDetailsView(receiverUser: user),
          ),
          settings: settings,
        );

      case AppRoutes.groupChatRoute:
        final group = settings.arguments as GroupModel;
        return _buildRoute(GroupChatView(group: group), settings: settings);

      case AppRoutes.editProfileViewRoute:
        final user = settings.arguments as UserData;
        return _buildRoute(
          BlocProvider(
            create: (context) => EditProfileCubit(EditProfileServices()),
            child: EditProfileView(userData: user),
          ),
          settings: settings,
        );

      case AppRoutes.profileViewRoute:
        final userId = settings.arguments as String;
        return _buildRoute(
          Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create:
                      (context) =>
                          ProfileCubit(HomeServices())..getProfileData(userId),
                ),
                BlocProvider(create: (context) => HomeCubit()),
              ],
              child: ProfileView(userId: userId),
            ),
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
