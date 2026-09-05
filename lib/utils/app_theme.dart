import 'package:flutter/material.dart';

/// Central Design System tokens for Raja Rani Traditional Tamil Theme
class AppColors {
  /// Warm Cream background (#F4E8D0)
  static const Color warmCream = Color(0xFFF4E8D0);

  /// Terracotta primary action/brand color (#A94A32)
  static const Color terracotta = Color(0xFFA94A32);

  /// Dark Brown typography and borders (#3B2418)
  static const Color darkBrown = Color(0xFF3B2418);

  /// Leaf Green secondary action/ready accent (#315C3A)
  static const Color leafGreen = Color(0xFF315C3A);

  /// Muted Turmeric highlight color (#D19A32)
  static const Color turmeric = Color(0xFFD19A32);

  /// Traditional Function Card Cream (#FFF8E8)
  static const Color cardCream = Color(0xFFFFF8E8);

  /// Subtle Border Tint
  static const Color borderBrown = Color(0xFF8C5840);

  /// Role Specific Traditional Accent Colors
  static const Color roleRaja = Color(0xFFA94A32); // Terracotta
  static const Color roleRani = Color(0xFFC76B55); // Terracotta / Floral Accent
  static const Color roleManthiri = Color(0xFF315C3A); // Leaf Green
  static const Color roleSippai = Color(0xFF426B4A); // Deep Green
  static const Color rolePolice = Color(0xFF3B2418); // Dark Brown
  static const Color roleThirudan = Color(0xFF7A3020); // Deep Terracotta
}

class AppTypography {
  static const TextStyle displayTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: AppColors.darkBrown,
    letterSpacing: 1.5,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.darkBrown,
    letterSpacing: 0.8,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.darkBrown,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: Color(0xFF6B4838),
  );
}

class AppDecorations {
  static BoxDecoration traditionalCard({
    Color backgroundColor = AppColors.cardCream,
    Color borderColor = AppColors.terracotta,
    double borderWidth = 1.5,
    double borderRadius = 16.0,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1F3B2418),
          blurRadius: 10,
          spreadRadius: 1,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}
