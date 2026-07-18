import 'package:flutter/material.dart';

enum ContentPrivacy { public, friends, private }

ContentPrivacy contentPrivacyFromString(String? value) {
  switch (value) {
    case 'friends':
      return ContentPrivacy.friends;
    case 'private':
      return ContentPrivacy.private;
    default:
      return ContentPrivacy.public;
  }
}

String contentPrivacyToString(ContentPrivacy privacy) {
  switch (privacy) {
    case ContentPrivacy.friends:
      return 'friends';
    case ContentPrivacy.private:
      return 'private';
    case ContentPrivacy.public:
      return 'public';
  }
}

extension ContentPrivacyUI on ContentPrivacy {
  IconData get icon => switch (this) {
    ContentPrivacy.public => Icons.public,
    ContentPrivacy.friends => Icons.people_alt_rounded,
    ContentPrivacy.private => Icons.lock_outline,
  };
  String get label => switch (this) {
    ContentPrivacy.public => 'Public',
    ContentPrivacy.friends => 'Friends',
    ContentPrivacy.private => 'Private',
  };
}
