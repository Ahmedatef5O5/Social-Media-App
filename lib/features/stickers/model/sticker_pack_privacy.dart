enum StickerPackPrivacy { public, private, friends }

extension StickerPackPrivacyX on StickerPackPrivacy {
  String get dbValue {
    switch (this) {
      case StickerPackPrivacy.public:
        return 'public';
      case StickerPackPrivacy.private:
        return 'private';
      case StickerPackPrivacy.friends:
        return 'friends';
    }
  }

  String get label {
    switch (this) {
      case StickerPackPrivacy.public:
        return 'Public';
      case StickerPackPrivacy.private:
        return 'Private';
      case StickerPackPrivacy.friends:
        return 'Specific Friends';
    }
  }

  static StickerPackPrivacy fromDbValue(String? value) {
    switch (value) {
      case 'private':
        return StickerPackPrivacy.private;
      case 'friends':
        return StickerPackPrivacy.friends;
      default:
        return StickerPackPrivacy.public;
    }
  }
}
