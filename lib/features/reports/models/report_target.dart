enum ReportTargetType {
  post('post'),
  comment('comment'),
  story('story'),
  message('message'),
  groupMessage('group_message'),
  user('user');

  const ReportTargetType(this.dbValue);
  final String dbValue;

  /// Lower-case noun used in UI copy ("Report post").
  String get label => switch (this) {
    ReportTargetType.post => 'post',
    ReportTargetType.comment => 'comment',
    ReportTargetType.story => 'story',
    ReportTargetType.message => 'message',
    ReportTargetType.groupMessage => 'message',
    ReportTargetType.user => 'profile',
  };
}

class ReportTarget {
  final ReportTargetType type;
  final String id;

  const ReportTarget({required this.type, required this.id});
}
