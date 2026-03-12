import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/features/profile/cubit/profile_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/profile_header.dart';
import '../widgets/proflie_states_widget.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final userId = Supabase.instance.client.auth.currentUser!.id;
    return BlocProvider(
      create: (context) => ProfileCubit()..getProfileData(userId),
      child: Center(
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return Center(
                child: CupertinoActivityIndicator(color: AppColors.black12),
              );
            } else if (state is ProfileLoaded) {
              return MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ProfileHeader(size: size, user: state.user),
                      Gap(20),
                      ProfileStatsWidget(stats: state.stats),
                    ],
                  ),
                ),
              );
            } else if (state is ProfileError) {
              return Center(child: Text(state.message));
            } else {
              return SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }
}
