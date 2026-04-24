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
import 'package:social_media_app/features/chats/views/receiver_profile_view.dart';
import 'package:social_media_app/features/discover/cubit/discover_people_cubit.dart';
import 'package:social_media_app/features/discover/services/discover_people_services.dart';
import 'package:social_media_app/features/group_chat/cubit/group_details_cubit/group_details_cubit.dart';
import 'package:social_media_app/features/group_chat/models/group_model.dart';
import 'package:social_media_app/features/group_chat/views/group_chat_details_view.dart';
import 'package:social_media_app/features/group_chat/views/group_info_view.dart';
import 'package:social_media_app/features/home/cubits/home_cubit/home_cubit.dart';
import 'package:social_media_app/features/home/services/home_services.dart';
import 'package:social_media_app/features/stories/views/add_story_preview_view.dart';
import 'package:social_media_app/features/home/views/create_post_view.dart';
import 'package:social_media_app/features/home/views/post_themes_view.dart';
import 'package:social_media_app/features/stories/views/story_display_view.dart';
import 'package:social_media_app/features/home/widgets/full_screen_image_viewer.dart';
import 'package:social_media_app/features/profile/cubits/edit_profile_cubit/edit_profile_cubit.dart';
import 'package:social_media_app/features/profile/services/edit_profile_services.dart';
import 'package:social_media_app/features/profile/views/edit_profile_view.dart';
import 'package:social_media_app/features/settings/views/settings_view.dart';
import 'package:social_media_app/features/splash/views/on_boarding_view.dart';
import 'package:social_media_app/features/splash/views/splash_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/data/models/user_data.dart';
import '../../features/calls/model/call_model.dart';
import '../../features/calls/views/dialing_view.dart';
import '../../features/calls/views/incoming_call_view.dart';
import '../../features/calls/views/zego_call_view.dart';
import '../../features/chats/cubit/chats_cubit/chats_cubit.dart';
import '../../features/group_chat/cubit/group_list_cubit/group_list_cubit.dart';
import '../../features/group_chat/services/group_chat_services.dart';
import '../../features/group_chat/views/create_group_view.dart';
import '../../features/stories/views/add_story_caption_view.dart';
import '../../features/stories/views/creat_text_story_view.dart';
import '../../features/profile/cubits/profile_cubit/profile_cubit.dart';
import '../../features/profile/views/profile_view.dart';

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
              BlocProvider(
                create:
                    (context) =>
                        DiscoverPeopleCubit(DiscoverPeopleServices())
                          ..getDiscoverPeople(),
              ),
              BlocProvider(
                create: (context) => ChatsCubit(ChatServices())..monitorChats(),
              ),
              BlocProvider(
                create:
                    (context) =>
                        GroupListCubit(GroupChatServices())..monitorGroups(),
              ),
            ],
            child: const CustomBottomNavBar(),
          ),
          settings: settings,
        );

      case AppRoutes.incomingCallRoute:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final call = CallModel(
          callId: args['callId'] as String? ?? '',
          callerId: args['callerId'] as String? ?? '',
          callerName: args['callerName'] as String? ?? 'Unknown',
          callerAvatar: args['callerAvatar'] as String? ?? '',
          receiverId: Supabase.instance.client.auth.currentUser?.id ?? '',
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
        final call = settings.arguments as CallModel;
        return _buildRoute(
          typeOfRoute: TypeOfRoute.material,
          DialingView(call: call),
          settings: settings,
        );

      case AppRoutes.callRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          typeOfRoute: TypeOfRoute.material,
          ZegoCallView(
            call: args['call'],
            currentUserId: args['userId'],
            currentUserName: args['userName'],
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

      case AppRoutes.addStoryPreviewViewRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          AddStoryPreviewView(
            file: args['file'] as File,
            isVideo: args['isVideo'] as bool,
            videoDuration: args['videoDuration'] as Duration?,
            homeCubit: args['homeCubit'] as HomeCubit,
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
            create:
                (context) =>
                    ChatDetailsCubit(ChatServices(), user.name)
                      ..loadCurrentUserInfo(),
            child: ChatDetailsView(receiverUser: user),
          ),
          settings: settings,
        );

      case AppRoutes.receiverProfileViewRoute:
        final user = settings.arguments as ChatUserModel;
        return _buildRoute(
          ReceiverProfileView(receiverUser: user),
          settings: settings,
        );

      case AppRoutes.createGroupRoute:
        return _buildRoute(
          BlocProvider(
            create: (_) => GroupListCubit(GroupChatServices()),
            child: const CreateGroupView(),
          ),

          settings: settings,
        );

      case AppRoutes.groupChatRoute:
        final group = settings.arguments as GroupModel;
        final services = GroupChatServices();
        return _buildRoute(
          BlocProvider(
            create:
                (context) => GroupDetailsCubit(
                  services,
                  group,
                  context.read<GroupListCubit>(),
                )..init(),
            child: GroupChatDetailsView(group: group),
          ),
          settings: settings,
        );

      case AppRoutes.groupInfoViewRoute:
        final group = settings.arguments as GroupModel;
        return _buildRoute(
          typeOfRoute: TypeOfRoute.material,
          GroupInfoView(group: group),
          settings: settings,
        );

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
