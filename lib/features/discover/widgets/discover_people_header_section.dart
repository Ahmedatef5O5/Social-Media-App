import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/custom_header_widget.dart';
import '../../../core/constants/app_images.dart';
import '../views/search_view.dart';

class DiscoverPeopleHeaderSection extends StatelessWidget {
  const DiscoverPeopleHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomHeader(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      title: 'Discover People',
      style: Theme.of(context).textTheme.titleLarge!.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      actions: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.of(context, rootNavigator: true).push(
            PageRouteBuilder(
              pageBuilder: (_, animation, __) => const SearchView(),
              transitionsBuilder: (_, anim, __, child) {
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: anim, curve: Curves.easeOut),
                    ),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 280),
            ),
          );
        },
        child: Image.asset(
          AppImages.searchIcon,
          width: 24,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
