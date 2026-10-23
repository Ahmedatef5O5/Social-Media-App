import 'package:flutter/cupertino.dart';
import '../../../core/localization/l10n_extension.dart';

enum CommentSortOption { newest, oldest, mostRelevant }

extension CommentSortOptionX on CommentSortOption {
  String localizedName(BuildContext context) => switch (this) {
    CommentSortOption.newest => context.l10n.sortNewest,
    CommentSortOption.oldest => context.l10n.sortOldest,
    CommentSortOption.mostRelevant => context.l10n.sortTop,
  };

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
