import 'package:flutter/material.dart';

class FaqItem {
  final String question;
  final String answer;

  const FaqItem({required this.question, required this.answer});

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }
}

class FaqCategory {
  final String title;
  final IconData icon;
  final List<FaqItem> items;

  const FaqCategory({
    required this.title,
    required this.icon,
    required this.items,
  });

  factory FaqCategory.fromJson(Map<String, dynamic> json) {
    return FaqCategory(
      title: json['title'] as String? ?? '',
      icon: _iconFromName(json['icon'] as String?),
      items:
          (json['items'] as List<dynamic>? ?? const [])
              .map((e) => FaqItem.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  // Icon names are mapped explicitly (not built from a raw code point) so
  // Flutter's icon tree-shaker can still see every icon this app actually
  // uses at compile time.
  static IconData _iconFromName(String? name) {
    switch (name) {
      case 'person_outline':
        return Icons.person_outline_rounded;
      case 'chat_bubble_outline':
        return Icons.chat_bubble_outline_rounded;
      case 'shield_outlined':
        return Icons.shield_outlined;
      case 'notifications_none':
        return Icons.notifications_none_rounded;
      case 'build_outlined':
        return Icons.build_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }
}
