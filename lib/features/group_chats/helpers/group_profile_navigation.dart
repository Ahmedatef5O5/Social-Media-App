import 'package:flutter/material.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import '../models/group_model.dart';
import '../models/group_view_args.dart';

/// Single entry point to a group's profile from anywhere in the app (post
/// header, search, repost, notification, deep link). The GroupView itself
/// decides between the full view (members) and the preview/join page
/// (non-members) from `get_group_profile`, so callers never need to know the
/// membership state.
Future<T?> openGroupProfile<T>(
  BuildContext context, {
  required String groupId,
  GroupModel? group,
}) {
  final current = ModalRoute.of(context);
  if (current?.settings.name == AppRoutes.groupViewRoute &&
      GroupViewArgs.from(current?.settings.arguments)?.groupId == groupId) {
    return Future.value(null); // already on this group
  }
  return Navigator.of(context, rootNavigator: true).pushNamed<T>(
    AppRoutes.groupViewRoute,
    arguments: GroupViewArgs(groupId: groupId, group: group),
  );
}

/// True when [context] currently shows the profile of [groupId].
bool isOnGroupProfile(BuildContext context, String groupId) {
  final route = ModalRoute.of(context);
  return route?.settings.name == AppRoutes.groupViewRoute &&
      GroupViewArgs.from(route?.settings.arguments)?.groupId == groupId;
}
