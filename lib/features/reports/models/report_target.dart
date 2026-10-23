import 'package:flutter/widgets.dart';
import '../../../core/localization/l10n_extension.dart';

enum ReportTargetType {
  post('post'),
  comment('comment'),
  story('story'),
  message('message'),
  groupMessage('group_message'),
  user('user');

  const ReportTargetType(this.dbValue);
  final String dbValue;

  String localizedLabel(BuildContext context) => switch (this) {
    ReportTargetType.post => context.l10n.targetPost,
    ReportTargetType.comment => context.l10n.targetComment,
    ReportTargetType.story => context.l10n.targetStory,
    ReportTargetType.message => context.l10n.targetMessage,
    ReportTargetType.groupMessage => context.l10n.targetMessage,
    ReportTargetType.user => context.l10n.targetProfile,
  };
}

class ReportTarget {
  final ReportTargetType type;
  final String id;

  const ReportTarget({required this.type, required this.id});
}
