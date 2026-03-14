import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/widgets/custom_bottom_nav_bar.dart';
import 'package:social_media_app/features/auth/views/auth_view.dart';
import 'package:social_media_app/features/discover/cubit/discover_people_cubit.dart';
import 'package:social_media_app/features/discover/services/discover_people_services.dart';
import 'package:social_media_app/features/home/cubit/home_cubit.dart';
import 'package:social_media_app/features/home/views/create_post_view.dart';
import 'package:social_media_app/features/profile/cubits/edit_profile_cubit/edit_profile_cubit.dart';
import 'package:social_media_app/features/profile/services/edit_profile_services.dart';
import 'package:social_media_app/features/profile/views/edit_profile_view.dart';
import '../../features/auth/data/models/user_data.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.authRoute:
        return CupertinoPageRoute(
          builder: (_) => const AuthView(),
          settings: settings,
        );

      case AppRoutes.homeRoute:
        return CupertinoPageRoute(
          builder:
              (_) => MultiBlocProvider(
                providers: [
                  BlocProvider(create: (context) => HomeCubit()..getHomeData()),
                  BlocProvider(
                    create:
                        (context) =>
                            DiscoverPeopleCubit(DiscoverPeopleServices())
                              ..getDiscoverPeople(),
                  ),
                ],
                child: const CustomBottomNavBar(),
              ),
          settings: settings,
        );

      case AppRoutes.createPostRoute:
        return CupertinoPageRoute(
          builder:
              (_) => BlocProvider.value(
                value: settings.arguments as HomeCubit,
                child: const CreatePostView(),
              ),
          settings: settings,
        );
      case AppRoutes.editProfileViewRoute:
        final user = settings.arguments as UserData;
        return CupertinoPageRoute(
          builder:
              (_) => BlocProvider(
                create: (context) => EditProfileCubit(EditProfileServices()),
                child: EditProfileView(userData: user),
              ),
          settings: settings,
        );

      default:
        return CupertinoPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'No route found ${settings.name}',
                        style: TextStyle(
                          color: AppColors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          settings: settings,
        );
    }
  }
}
