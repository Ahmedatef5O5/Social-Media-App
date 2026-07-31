import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../discover/cubit/discover_people_cubit.dart';
import '../../discover/widgets/discover_person_card_widget.dart';

class SuggestedAccountsSection extends StatelessWidget {
  const SuggestedAccountsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<DiscoverPeopleCubit, DiscoverPeopleState>(
      builder: (context, state) {
        final users = state is DiscoverPeopleSuccess ? state.users : const [];
        if (users.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Gap(10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Suggested for you',
                style: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Gap(10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < users.length; i++) ...[
                    if (i > 0) const Gap(10),
                    SizedBox(
                      width: 260,
                      child: DiscoverPersonCardWidget(
                        key: ValueKey(users[i].user.id),
                        personData: users[i],
                        boxShadow: [
                          BoxShadow(
                            color:
                                theme.brightness == Brightness.dark
                                    ? Colors.black.withValues(alpha: 0.35)
                                    : Colors.black.withValues(alpha: 0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Gap(5),
          ],
        );
      },
    );
  }
}
