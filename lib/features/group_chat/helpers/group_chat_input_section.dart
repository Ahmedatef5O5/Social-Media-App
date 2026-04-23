import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../models/groupe_message_model.dart';

class GroupChatHelpers {
  static bool shouldShowDate(List<GroupMessageModel> messages, int index) {
    if (index == messages.length - 1) return true;

    final current = messages[index];
    final prev = messages[index + 1];

    return current.createdAt.day != prev.createdAt.day;
  }

  static Future<void> pickAndSendImage(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null && context.mounted) {
      context.read<GroupDetailsCubit>().sendMessage(
        text: '',
        messageType: 'image',
        imageFile: File(picked.path),
      );
    }
  }
}
