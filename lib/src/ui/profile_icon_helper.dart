import 'package:flutter/material.dart';

/// Helper class to get appropriate profile icons based on age and gender
class ProfileIconHelper {
  ProfileIconHelper._();

  /// Get icon based on age and gender
  /// Returns a Widget (either Icon or Text emoji) suitable for profile display
  static Widget getProfileIcon({
    int? age,
    String? gender,
    double size = 40,
    Color? color,
  }) {
    final iconColor = color ?? Colors.grey[700]!;

    // If no age or gender provided, return default person icon
    if (age == null || gender == null) {
      return Icon(Icons.person, size: size, color: iconColor);
    }

    final isMale = gender.toLowerCase() == 'male' || gender.toLowerCase() == 'm';

    // Categorize by age
    if (age < 13) {
      // Child
      return _buildEmojiIcon(isMale ? '👦' : '👧', size);
    } else if (age < 18) {
      // Teenager
      return _buildEmojiIcon(isMale ? '🧑' : '👧', size);
    } else if (age < 60) {
      // Adult
      return _buildEmojiIcon(isMale ? '👨' : '👩', size);
    } else {
      // Senior/Elderly
      return _buildEmojiIcon(isMale ? '👴' : '👵', size);
    }
  }

  /// Build an emoji icon widget
  static Widget _buildEmojiIcon(String emoji, double size) {
    return Text(emoji, style: TextStyle(fontSize: size));
  }

  /// Get Material icon alternative
  static IconData getMaterialIcon({int? age, String? gender}) {
    if (age == null || gender == null) {
      return Icons.person;
    }

    final isMale = gender.toLowerCase() == 'male' || gender.toLowerCase() == 'm';

    // Material Icons don't have as granular age categories
    // but we can use face icons or person icons
    if (age < 18) {
      return Icons.child_care; // Child icon
    } else if (age < 60) {
      return isMale ? Icons.man : Icons.woman; // Adult
    } else {
      return Icons.elderly; // Senior (if available in newer Flutter versions)
    }
  }

  /// Get color theme based on gender
  static Color getGenderColor(String? gender, {double opacity = 1.0}) {
    if (gender == null) return Colors.grey.withOpacity(opacity);

    final isMale = gender.toLowerCase() == 'male' || gender.toLowerCase() == 'm';
    return isMale ? Colors.blue.withOpacity(opacity) : Colors.pink.withOpacity(opacity);
  }

  /// Get descriptive label for age/gender combination
  static String getAgeGenderLabel({int? age, String? gender}) {
    if (age == null || gender == null) return 'Member';

    final isMale = gender.toLowerCase() == 'male' || gender.toLowerCase() == 'm';

    if (age < 13) {
      return isMale ? 'Boy' : 'Girl';
    } else if (age < 18) {
      return isMale ? 'Teen Boy' : 'Teen Girl';
    } else if (age < 60) {
      return isMale ? 'Man' : 'Woman';
    } else {
      return isMale ? 'Grandfather' : 'Grandmother';
    }
  }
}
