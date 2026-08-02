enum GroupMembershipStatus { active, left, removed }

GroupMembershipStatus groupMembershipStatusFromString(String? raw) {
  switch (raw) {
    case 'left':
      return GroupMembershipStatus.left;
    case 'removed':
      return GroupMembershipStatus.removed;
    default:
      return GroupMembershipStatus.active;
  }
}
