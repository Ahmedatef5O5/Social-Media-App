import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/core/widgets/custom_pull_to_refresh.dart';
import 'package:social_media_app/features/discover/cubit/discover_people_cubit.dart';
import '../widgets/discover_people_header_section.dart';
import '../widgets/discover_person_card_widget.dart';

class DiscoverView extends StatelessWidget {
  const DiscoverView({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundThemeWidget(
      top: true,
      child: CustomPullToRefresh(
        onRefresh:
            () async => await context
                .read<DiscoverPeopleCubit>()
                .getDiscoverPeople(isRefresh: true),
        child: Column(
          children: [
            const Gap(20),
            DiscoverPeopleHeaderSection(),
            const Gap(8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: BlocBuilder<DiscoverPeopleCubit, DiscoverPeopleState>(
                  builder: (context, state) {
                    if (state is DiscoverPeopleLoading) {
                      return const CustomLoadingIndicator();
                    }
                    if (state is DiscoverPeopleSuccess) {
                      return ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: ClampingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.only(
                          top: 14,
                          left: 0,
                          right: 0,
                          bottom: 100,
                        ),
                        itemCount: state.users.length,
                        separatorBuilder:
                            (BuildContext context, int index) => const Gap(16),

                        itemBuilder: (BuildContext context, int index) {
                          return DiscoverPersonCardWidget(
                            userData: state.users[index],
                          );
                        },
                      );
                    } else if (state is DiscoverPeopleFailure) {
                      return Center(child: Text(state.message));
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ),
            ),
            const Gap(20),
          ],
        ),
      ),
    );
  }
}
