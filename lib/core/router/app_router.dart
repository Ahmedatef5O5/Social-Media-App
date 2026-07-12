import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/views/loading_screen.dart';
import 'package:social_media_app/core/views/no_route_screen.dart';
import 'package:social_media_app/core/widgets/custom_bottom_nav_bar.dart';
import 'package:social_media_app/features/auth/views/auth_view.dart';
import 'package:social_media_app/features/single_chats/cubit/chat_details_cubit/chat_details_cubit.dart';
import 'package:social_media_app/features/single_chats/models/chat_user_model.dart';
import 'package:social_media_app/features/single_chats/services/chat_services.dart';
import 'package:social_media_app/features/single_chats/views/chat_details_view.dart';
import 'package:social_media_app/features/single_chats/views/chats_view.dart';
import 'package:social_media_app/features/single_chats/views/receiver_profile_view.dart';
import 'package:social_media_app/features/discover/cubit/discover_people_cubit.dart';
import 'package:social_media_app/features/discover/services/discover_people_services.dart';
import 'package:social_media_app/features/group_chats/cubit/group_details_cubit/group_details_cubit.dart';
import 'package:social_media_app/features/group_chats/models/group_model.dart';
import 'package:social_media_app/features/group_chats/views/group_chat_details_view.dart';
import 'package:social_media_app/features/group_chats/views/group_info_view.dart';
import 'package:social_media_app/features/profile/services/user_services.dart';
import 'package:social_media_app/features/stories/views/add_story_preview_view.dart';
import 'package:social_media_app/features/posts/views/create_post_view.dart';
import 'package:social_media_app/features/posts/views/post_themes_view.dart';
import 'package:social_media_app/features/stories/views/story_display_view.dart';
import 'package:social_media_app/core/widgets/full_screen_image_viewer.dart';
import 'package:social_media_app/features/profile/cubits/edit_profile_cubit/edit_profile_cubit.dart';
import 'package:social_media_app/features/profile/services/edit_profile_services.dart';
import 'package:social_media_app/features/profile/views/edit_profile_view.dart';
import 'package:social_media_app/features/settings/views/settings_view.dart';
import 'package:social_media_app/features/splash/views/on_boarding_view.dart';
import 'package:social_media_app/features/splash/views/splash_view.dart';
import '../../features/auth/data/models/user_data.dart';
import '../../features/posts/cubit/posts_cubit.dart';
import '../../features/single_calls/model/call_model.dart';
import '../../features/single_calls/views/dialing_view.dart';
import '../../features/single_calls/views/incoming_call_view.dart';
import '../../features/single_calls/views/zego_call_view.dart';
import '../../features/single_chats/cubit/chats_cubit/chats_cubit.dart';
import '../../features/group_chats/cubit/group_list_cubit/group_list_cubit.dart';
import '../../features/group_chats/services/group_chat_services.dart';
import '../../features/group_chats/views/create_group_view.dart';
import '../../features/about_us/views/about_us_view.dart';
import '../../features/stories/cubit/stories_cubit/stories_cubit.dart';
import '../../features/stories/model/story_model.dart';
import '../../features/stories/views/add_story_caption_view.dart';
import '../../features/stories/views/creat_text_story_view.dart';
import '../../features/profile/cubits/profile_cubit/profile_cubit.dart';
import '../../features/profile/views/profile_view.dart';
import '../../features/stories/views/my_stories_list_view.dart';
import '../supabase/supabase_provider.dart';

enum TypeOfRoute { material, cupertino, fade }

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

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

  /// Safely extracts arguments to prevent casting crashes.
  static T? _args<T>(RouteSettings settings) {
    final args = settings.arguments;
    if (args is T) return args;
    debugPrint(
      '[AppRouter] ⚠️ Route "${settings.name}": '
      'expected ${T.toString()} but got ${args.runtimeType}',
    );
    return null;
  }

  /// Fallback route when argument casting fails.
  static Route<dynamic> _errorRoute(RouteSettings settings, [String? reason]) {
    return MaterialPageRoute(
      settings: settings,
      builder:
          (_) => Scaffold(
            appBar: AppBar(title: const Text('Navigation Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    reason ?? 'Unable to open this screen due to missing data',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Route: ${settings.name}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final name = settings.name ?? '';

    if (_isAuthCallback(name)) {
      return _buildRoute(const LoadingScreen());
    }

    // Routing mapped to modular helper functions
    switch (name) {
      case AppRoutes.splashViewRoute:
      case AppRoutes.onBoardingViewRoute:
      case AppRoutes.authRoute:
        return _authRoutes(settings);

      case AppRoutes.homeRoute:
      case AppRoutes.createPostViewRoute:
      case AppRoutes.postThemesViewRoute:
      case AppRoutes.fullScreenImageViewRoute:
        return _homeRoutes(settings);

      case AppRoutes.createTextStoryViewRoute:
      case AppRoutes.addStoryCaptionViewRoute:
      case AppRoutes.storyDisplayViewRoute:
      case AppRoutes.addStoryPreviewViewRoute:
      case AppRoutes.myStoriesListViewRoute:
        return _storyRoutes(settings);

      case AppRoutes.chatsViewRoute:
      case AppRoutes.chatDetailsViewRoute:
      case AppRoutes.receiverProfileViewRoute:
        return _chatRoutes(settings);

      case AppRoutes.createGroupRoute:
      case AppRoutes.groupChatRoute:
      case AppRoutes.groupInfoViewRoute:
        return _groupChatRoutes(settings);

      case AppRoutes.incomingCallRoute:
      case AppRoutes.dialingRoute:
      case AppRoutes.callRoute:
        return _callRoutes(settings);

      case AppRoutes.editProfileViewRoute:
      case AppRoutes.profileViewRoute:
      case AppRoutes.aboutUsViewRoute:
      case AppRoutes.settingsViewRoute:
        return _profileAndSettingsRoutes(settings);

      default:
        return _buildRoute(NoRouteScreen(routeName: name));
    }
  }

  // ─── Modular Route Handlers ───

  static Route<dynamic> _authRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splashViewRoute:
        return _buildRoute(const SplashView(), settings: settings);
      case AppRoutes.onBoardingViewRoute:
        return _buildRoute(const OnBoardingView(), settings: settings);
      case AppRoutes.authRoute:
        return _buildRoute(const AuthView(), settings: settings);
      default:
        return _errorRoute(settings, 'Auth route not found');
    }
  }

  static Route<dynamic> _homeRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.homeRoute:
        return _buildRoute(
          MultiBlocProvider(
            providers: [
              BlocProvider(
                create:
                    (context) => DiscoverPeopleCubit(
                      context.read<DiscoverPeopleServices>(),
                    )..getDiscoverPeople(),
              ),
              BlocProvider(
                create:
                    (context) =>
                        ChatsCubit(context.read<ChatServices>())
                          ..monitorChats(),
              ),
              BlocProvider(
                create:
                    (context) =>
                        GroupListCubit(context.read<GroupChatServices>())
                          ..monitorGroups(),
              ),
            ],
            child: const CustomBottomNavBar(),
          ),
          settings: settings,
        );
      case AppRoutes.createPostViewRoute:
        final cubit = _args<PostsCubit>(settings);
        if (cubit == null) {
          return _errorRoute(settings, 'Missing PostsCubit parameter');
        }
        return _buildRoute(
          BlocProvider.value(value: cubit, child: const CreatePostView()),
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
      default:
        return _errorRoute(settings, 'Home route not found');
    }
  }

  static Route<dynamic> _storyRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.createTextStoryViewRoute:
        final args = _args<Map<String, dynamic>>(settings);
        if (args == null ||
            args['storiesCubit'] is! StoriesCubit ||
            args['currentUser'] is! UserData) {
          return _errorRoute(
            settings,
            'Missing StoriesCubit/currentUser parameter',
          );
        }
        return _buildRoute(
          BlocProvider.value(
            value: args['storiesCubit'] as StoriesCubit,
            child: CreateTextStoryView(
              currentUser: args['currentUser'] as UserData,
            ),
          ),
          settings: settings,
        );
      case AppRoutes.addStoryCaptionViewRoute:
        final args = _args<Map<String, dynamic>>(settings);
        if (args == null ||
            args['file'] is! File ||
            args['storiesCubit'] is! StoriesCubit ||
            args['currentUser'] is! UserData) {
          return _errorRoute(settings, 'Invalid arguments for Story Caption');
        }
        return _buildRoute(
          AddStoryCaptionView(
            file: args['file'],
            storiesCubit: args['storiesCubit'],
            currentUser: args['currentUser'],
          ),
          settings: settings,
        );
      case AppRoutes.storyDisplayViewRoute:
        final args = _args<Map<String, dynamic>>(settings);
        if (args == null || args['storiesCubit'] is! StoriesCubit) {
          return _errorRoute(settings, 'Missing arguments for Story Display');
        }
        return _buildRoute(
          StoryDisplayView(
            storiesCubit: args['storiesCubit'],
            allUserGroups: args['allUserGroups'],
            initialGroupIndex: args['initialGroupIndex'],
            initialStoryIndex: args['initialStoryIndex'] as int? ?? 0,
          ),
          typeOfRoute: TypeOfRoute.fade,
          settings: settings,
        );
      case AppRoutes.addStoryPreviewViewRoute:
        final args = _args<Map<String, dynamic>>(settings);
        if (args == null ||
            args['file'] is! File ||
            args['isVideo'] is! bool ||
            args['storiesCubit'] is! StoriesCubit ||
            args['currentUser'] is! UserData) {
          return _errorRoute(settings, 'Invalid arguments for Story Preview');
        }
        return _buildRoute(
          AddStoryPreviewView(
            file: args['file'],
            isVideo: args['isVideo'],
            videoDuration: args['videoDuration'] as Duration?,
            storiesCubit: args['storiesCubit'],
            currentUser: args['currentUser'],
          ),
          typeOfRoute: TypeOfRoute.fade,
          settings: settings,
        );
      case AppRoutes.myStoriesListViewRoute:
        final args = _args<Map<String, dynamic>>(settings);
        if (args == null ||
            args['storiesCubit'] is! StoriesCubit ||
            args['myStories'] is! List<StoryModel>) {
          return _errorRoute(settings, 'Missing arguments for My Stories');
        }
        return _buildRoute(
          MyStoriesListView(
            storiesCubit: args['storiesCubit'] as StoriesCubit,
            myStories: args['myStories'] as List<StoryModel>,
          ),
          settings: settings,
        );
      default:
        return _errorRoute(settings, 'Story route not found');
    }
  }

  static Route<dynamic> _chatRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.chatsViewRoute:
        return _buildRoute(const ChatsView(), settings: settings);
      case AppRoutes.chatDetailsViewRoute:
        final user = _args<ChatUserModel>(settings);
        if (user == null) {
          return _errorRoute(settings, 'Missing ChatUserModel data');
        }
        return _buildRoute(
          BlocProvider(
            create:
                (context) =>
                    ChatDetailsCubit(context.read<ChatServices>(), user.name)
                      ..loadCurrentUserInfo(),
            child: ChatDetailsView(receiverUser: user),
          ),
          settings: settings,
        );
      case AppRoutes.receiverProfileViewRoute:
        final user = _args<ChatUserModel>(settings);
        if (user == null) {
          return _errorRoute(settings, 'Missing ChatUserModel data');
        }
        return _buildRoute(
          ReceiverProfileView(receiverUser: user),
          settings: settings,
        );
      default:
        return _errorRoute(settings, 'Chat route not found');
    }
  }

  static Route<dynamic> _groupChatRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.createGroupRoute:
        return _buildRoute(
          BlocProvider(
            create:
                (context) => GroupListCubit(context.read<GroupChatServices>()),
            child: const CreateGroupView(),
          ),
          settings: settings,
        );
      case AppRoutes.groupChatRoute:
        final group = _args<GroupModel>(settings);
        if (group == null) {
          return _errorRoute(settings, 'Missing GroupModel data');
        }
        return _buildRoute(
          BlocProvider(
            create:
                (context) => GroupDetailsCubit(
                  context.read<GroupChatServices>(),
                  group,
                  context.read<GroupListCubit>(),
                )..init(),
            child: GroupChatDetailsView(group: group),
          ),
          settings: settings,
        );
      case AppRoutes.groupInfoViewRoute:
        final group = _args<GroupModel>(settings);
        if (group == null) {
          return _errorRoute(settings, 'Missing GroupModel data');
        }
        return _buildRoute(
          GroupInfoView(group: group),
          typeOfRoute: TypeOfRoute.material,
          settings: settings,
        );
      default:
        return _errorRoute(settings, 'Group chat route not found');
    }
  }

  static Route<dynamic> _callRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.incomingCallRoute:
        final args = _args<Map<String, dynamic>>(settings) ?? {};
        final call = CallModel(
          callId: args['callId'] as String? ?? '',
          callerId: args['callerId'] as String? ?? '',
          callerName: args['callerName'] as String? ?? 'Unknown',
          callerAvatar: args['callerAvatar'] as String? ?? '',
          receiverId: SupabaseProvider.id,
          receiverName: '',
          receiverAvatar: '',
          status: CallStatus.ringing,
          type:
              (args['callType'] as String?) == 'video'
                  ? CallType.video
                  : CallType.audio,
        );
        return _buildRoute(
          IncomingCallView(call: call),
          settings: settings,
          typeOfRoute: TypeOfRoute.fade,
        );

      case AppRoutes.dialingRoute:
        final call = _args<CallModel>(settings);
        if (call == null) {
          return _errorRoute(settings, 'Missing CallModel parameter');
        }
        return _buildRoute(
          DialingView(call: call),
          typeOfRoute: TypeOfRoute.material,
          settings: settings,
        );

      case AppRoutes.callRoute:
        final args = _args<Map<String, dynamic>>(settings);
        if (args == null || args['call'] is! CallModel) {
          return _errorRoute(settings, 'Invalid or missing Call data');
        }
        return _buildRoute(
          ZegoCallView(
            call: args['call'],
            currentUserId: args['userId'],
            currentUserName: args['userName'],
          ),
          typeOfRoute: TypeOfRoute.material,
          settings: settings,
        );
      default:
        return _errorRoute(settings, 'Call route not found');
    }
  }

  static Route<dynamic> _profileAndSettingsRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.editProfileViewRoute:
        final user = _args<UserData>(settings);
        if (user == null) {
          return _errorRoute(settings, 'Missing UserData parameter');
        }
        return _buildRoute(
          BlocProvider(
            create: (context) => EditProfileCubit(EditProfileServices()),
            child: EditProfileView(userData: user),
          ),
          settings: settings,
        );
      case AppRoutes.profileViewRoute:
        final userId = _args<String>(settings);
        if (userId == null) {
          return _errorRoute(settings, 'Missing User ID parameter');
        }
        return _buildRoute(
          Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create:
                      (context) =>
                          ProfileCubit(context.read<UserService>())
                            ..getProfileData(userId),
                ),
              ],
              child: ProfileView(userId: userId),
            ),
          ),
          settings: settings,
        );
      case AppRoutes.aboutUsViewRoute:
        return _buildRoute(AboutUsView(), settings: settings);
      case AppRoutes.settingsViewRoute:
        final cubit = _args<ProfileCubit>(settings);
        if (cubit == null) {
          return _errorRoute(settings, 'Missing ProfileCubit');
        }
        return _buildRoute(
          BlocProvider.value(value: cubit, child: SettingsView()),
          settings: settings,
        );
      default:
        return _errorRoute(settings, 'Profile/Settings route not found');
    }
  }
}
