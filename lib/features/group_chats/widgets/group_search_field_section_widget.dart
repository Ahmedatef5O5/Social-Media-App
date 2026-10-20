import 'package:flutter/material.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;

  const SearchField({
    super.key,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: context.l10n.searchPeople2,
          prefixIcon: const Icon(Icons.search),
        ),
      ),
    );
  }
}
