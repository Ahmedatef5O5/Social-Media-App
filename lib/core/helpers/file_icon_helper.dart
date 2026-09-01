import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FileIconHelper {
  static (FaIconData, Color) getIconAndColor(
    String extension,
    Color defaultColor,
  ) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return (FontAwesomeIcons.solidFilePdf, const Color(0xFFE5252A));
      case 'doc':
      case 'docx':
        return (FontAwesomeIcons.solidFileWord, const Color(0xFF185ABD));
      case 'xls':
      case 'xlsx':
      case 'csv':
        return (FontAwesomeIcons.solidFileExcel, const Color(0xFF217346));
      case 'ppt':
      case 'pptx':
        return (FontAwesomeIcons.solidFilePowerpoint, const Color(0xFFD24726));
      case 'txt':
      case 'rtf':
        return (FontAwesomeIcons.solidFileLines, const Color(0xFF2E7D52));
      case 'md':
        return (FontAwesomeIcons.solidFileLines, const Color(0xFF3B82F6));
      case 'json':
      case 'dart':
      case 'py':
      case 'pyw':
      case 'js':
      case 'ts':
      case 'html':
      case 'htm':
      case 'css':
      case 'xml':
      case 'yaml':
      case 'yml':
      case 'java':
      case 'kt':
      case 'kts':
      case 'c':
      case 'cpp':
      case 'cc':
      case 'cxx':
      case 'h':
      case 'hpp':
      case 'cs':
      case 'swift':
      case 'go':
      case 'rb':
      case 'rs':
      case 'sql':
      case 'sh':
      case 'bat':
      case 'env':
        return (FontAwesomeIcons.solidFileCode, const Color(0xFF00B4D8));
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return (FontAwesomeIcons.solidFileZipper, const Color(0xFFF59E0B));
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'aac':
      case 'ogg':
        return (FontAwesomeIcons.solidFileAudio, const Color(0xFF9333EA));
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return (FontAwesomeIcons.solidFileVideo, const Color(0xFFE11D48));
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'webp':
      case 'gif':
        return (FontAwesomeIcons.solidFileImage, const Color(0xFF059669));
      default:
        return (FontAwesomeIcons.solidFile, defaultColor);
    }
  }
}
