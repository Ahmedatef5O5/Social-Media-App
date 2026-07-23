enum PresencePrivacy {
  everyone('everyone'),
  friends('friends'),
  specific('specific'),
  nobody('nobody');

  const PresencePrivacy(this.value);
  final String value;

  static PresencePrivacy fromValue(String? value) {
    return PresencePrivacy.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PresencePrivacy.friends,
    );
  }
}
