import 'group_model.dart';

/// Arguments for [AppRoutes.groupViewRoute] / [AppRoutes.groupPreviewJoinViewRoute].
/// Only [groupId] is required (deep links, post headers); [group] is an
/// optional hint used to paint the header instantly while the profile loads.
class GroupViewArgs {
  final String groupId;
  final GroupModel? group;

  const GroupViewArgs({required this.groupId, this.group});

  static GroupViewArgs? from(Object? raw) {
    if (raw is GroupViewArgs) return raw;
    if (raw is GroupModel) return GroupViewArgs(groupId: raw.id, group: raw);
    if (raw is String && raw.isNotEmpty) return GroupViewArgs(groupId: raw);
    return null;
  }
}
