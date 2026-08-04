class GroupAddMembersResult {
  final List<String> added;
  final List<String> failed;

  const GroupAddMembersResult({required this.added, required this.failed});

  bool get isFullSuccess => failed.isEmpty;
  bool get isPartialSuccess => added.isNotEmpty && failed.isNotEmpty;
  bool get isFullFailure => added.isEmpty && failed.isNotEmpty;
}

class GroupMembersUnavailableException implements Exception {
  final String message;
  const GroupMembersUnavailableException([
    this.message = "This person isn't available to join the group right now.",
  ]);

  @override
  String toString() => message;
}
