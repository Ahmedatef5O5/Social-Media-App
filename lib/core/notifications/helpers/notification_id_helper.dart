/// Deterministic small-int id derived from any string key (conversation id,
/// call id, etc.) — used as the local-notification id so the same
/// conversation/call always maps to the same notification slot, and so it
/// can be recreated later (e.g. to cancel it) from just the key.
int createNotificationId(String input) {
  int hash = 0;
  for (int i = 0; i < input.length; i++) {
    hash = 31 * hash + input.codeUnitAt(i);
  }
  return hash & 0x7FFFFFFF;
}
