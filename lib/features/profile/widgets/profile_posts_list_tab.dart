import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../home/cubit/home_cubit.dart';
import '../../home/widgets/post_item_widget.dart';

class ProfilePostsListTab extends StatelessWidget {
  final String userId;
  const ProfilePostsListTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is PostsLoaded) {
          final userPosts =
              state.posts.where((p) => p.authorId == userId).toList();

          if (userPosts.isEmpty) {
            return const Center(child: Text('No posts yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            // physics: const NeverScrollableScrollPhysics(),
            // shrinkWrap: true,
            itemCount: userPosts.length,
            itemBuilder:
                (context, index) => PostItemWidget(post: userPosts[index]),
            separatorBuilder: (BuildContext context, int index) => Gap(20),
          );
        }
        return const CustomLoadingIndicator();
      },
    );
  }
}
