enum FriendshipStatus { none, pendingSent, pendingReceived, accepted }

FriendshipStatus friendshipStatusFromString(String? value) {
  switch (value) {
    case 'pending_sent':
      return FriendshipStatus.pendingSent;
    case 'pending_received':
      return FriendshipStatus.pendingReceived;
    case 'accepted':
      return FriendshipStatus.accepted;
    default:
      return FriendshipStatus.none;
  }
}
