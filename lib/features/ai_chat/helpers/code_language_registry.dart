import 'package:flutter/material.dart';

class CodeLanguageMeta {
  final String label;
  final Color accentColor;
  final IconData icon;

  const CodeLanguageMeta({
    required this.label,
    required this.accentColor,
    required this.icon,
  });
}

class CodeLanguageRegistry {
  static const Map<String, CodeLanguageMeta> _known = {
    'dart': CodeLanguageMeta(
      label: 'Dart',
      accentColor: Color(0xFF54C5F8),
      icon: Icons.flutter_dash,
    ),
    'cpp': CodeLanguageMeta(
      label: 'C++',
      accentColor: Color(0xFF659AD2),
      icon: Icons.memory,
    ),
    'c': CodeLanguageMeta(
      label: 'C',
      accentColor: Color(0xFF659AD2),
      icon: Icons.memory,
    ),
    'python': CodeLanguageMeta(
      label: 'Python',
      accentColor: Color(0xFFFFD43B),
      icon: Icons.data_object,
    ),
    'javascript': CodeLanguageMeta(
      label: 'JavaScript',
      accentColor: Color(0xFFF0DB4F),
      icon: Icons.code,
    ),
    'js': CodeLanguageMeta(
      label: 'JavaScript',
      accentColor: Color(0xFFF0DB4F),
      icon: Icons.code,
    ),
    'typescript': CodeLanguageMeta(
      label: 'TypeScript',
      accentColor: Color(0xFF3178C6),
      icon: Icons.code,
    ),
    'ts': CodeLanguageMeta(
      label: 'TypeScript',
      accentColor: Color(0xFF3178C6),
      icon: Icons.code,
    ),
    'java': CodeLanguageMeta(
      label: 'Java',
      accentColor: Color(0xFFEA6C3C),
      icon: Icons.coffee,
    ),
    'kotlin': CodeLanguageMeta(
      label: 'Kotlin',
      accentColor: Color(0xFFB388FF),
      icon: Icons.code,
    ),
    'swift': CodeLanguageMeta(
      label: 'Swift',
      accentColor: Color(0xFFF05138),
      icon: Icons.code,
    ),
    'json': CodeLanguageMeta(
      label: 'JSON',
      accentColor: Color(0xFF8BC34A),
      icon: Icons.data_object,
    ),
    'yaml': CodeLanguageMeta(
      label: 'YAML',
      accentColor: Color(0xFF8BC34A),
      icon: Icons.data_object,
    ),
    'yml': CodeLanguageMeta(
      label: 'YAML',
      accentColor: Color(0xFF8BC34A),
      icon: Icons.data_object,
    ),
    'bash': CodeLanguageMeta(
      label: 'Bash',
      accentColor: Color(0xFF4EAA25),
      icon: Icons.terminal,
    ),
    'sh': CodeLanguageMeta(
      label: 'Shell',
      accentColor: Color(0xFF4EAA25),
      icon: Icons.terminal,
    ),
    'sql': CodeLanguageMeta(
      label: 'SQL',
      accentColor: Color(0xFF4FC3F7),
      icon: Icons.storage,
    ),
    'html': CodeLanguageMeta(
      label: 'HTML',
      accentColor: Color(0xFFE34C26),
      icon: Icons.code,
    ),
    'css': CodeLanguageMeta(
      label: 'CSS',
      accentColor: Color(0xFF42A5F5),
      icon: Icons.code,
    ),
    'xml': CodeLanguageMeta(
      label: 'XML',
      accentColor: Color(0xFFE34C26),
      icon: Icons.data_object,
    ),
  };

  static CodeLanguageMeta resolve(String? rawLanguage) {
    final key = (rawLanguage ?? '').trim().toLowerCase();
    return _known[key] ??
        CodeLanguageMeta(
          label: key.isEmpty ? 'Code' : key,
          accentColor: const Color(0xFF9E9E9E),
          icon: Icons.code,
        );
  }
}
