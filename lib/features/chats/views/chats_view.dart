import 'package:flutter/material.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import '../widgets/chats_view_body.dart';

class ChatsView extends StatelessWidget {
  const ChatsView({super.key});
  @override
  Widget build(BuildContext context) {
    return BackgroundThemeWidget(child: Center(child: ChatsViewBody()));
  }
}
