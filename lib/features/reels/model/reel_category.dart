import 'package:flutter/material.dart';

class ReelCategoryOption {
  final String value;
  final String label;
  final IconData icon;

  const ReelCategoryOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}

class ReelCategories {
  const ReelCategories._();

  static const List<ReelCategoryOption> all = [
    ReelCategoryOption(
      value: 'News',
      label: 'News',
      icon: Icons.newspaper_rounded,
    ),
    ReelCategoryOption(
      value: 'Football',
      label: 'Football',
      icon: Icons.sports_soccer_rounded,
    ),
    ReelCategoryOption(
      value: 'Tech',
      label: 'Tech',
      icon: Icons.memory_rounded,
    ),
    ReelCategoryOption(
      value: 'Comedy',
      label: 'Comedy',
      icon: Icons.emoji_emotions_rounded,
    ),
    ReelCategoryOption(
      value: 'Islamic',
      label: 'Islamic',
      icon: Icons.mosque_rounded,
    ),
    ReelCategoryOption(
      value: 'Cooking',
      label: 'Cooking',
      icon: Icons.restaurant_rounded,
    ),
    ReelCategoryOption(
      value: 'Gaming',
      label: 'Gaming',
      icon: Icons.sports_esports_rounded,
    ),
    ReelCategoryOption(
      value: 'Movies',
      label: 'Movies',
      icon: Icons.movie_rounded,
    ),
  ];
}
