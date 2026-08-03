import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ChatSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final ValueListenable<String> counterTextNotifier;
  final bool hasMatches;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onClose;

  const ChatSearchAppBar({
    super.key,
    required this.controller,
    this.focusNode,
    required this.onChanged,
    required this.counterTextNotifier,
    required this.hasMatches,
    required this.onPrevious,
    required this.onNext,
    required this.onClose,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: onClose,
      ),
      titleSpacing: 0,
      title: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: true,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          hintText: 'Search messages',
          border: InputBorder.none,
        ),
      ),
      actions: [
        ValueListenableBuilder<String>(
          valueListenable: counterTextNotifier,
          builder: (context, text, _) {
            if (text.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up_rounded),
          color: hasMatches ? primary : Colors.grey,
          onPressed: hasMatches ? onPrevious : null,
        ),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          color: hasMatches ? primary : Colors.grey,
          onPressed: hasMatches ? onNext : null,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
