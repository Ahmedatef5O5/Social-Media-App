import 'package:flutter/cupertino.dart';

enum CommentSortOption { newest, oldest, mostRelevant }

extension CommentSortOptionX on CommentSortOption {
  String get label => switch (this) {
    CommentSortOption.newest => 'Newest',
    CommentSortOption.oldest => 'Oldest',
    CommentSortOption.mostRelevant => 'Top',
  };

  IconData get icon => switch (this) {
    CommentSortOption.newest => CupertinoIcons.sparkles,
    CommentSortOption.oldest => CupertinoIcons.clock,
    CommentSortOption.mostRelevant => CupertinoIcons.flame,
  };
}
