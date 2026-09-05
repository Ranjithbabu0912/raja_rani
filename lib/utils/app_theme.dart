import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central Design System tokens for Real Notebook Paper Raja Rani Theme
class AppColors {
  /// Warm notebook paper background (#F7F1DF)
  static const Color warmPaper = Color(0xFFF7F1DF);
  static const Color warmCream = Color(0xFFF7F1DF); // backwards compatibility

  /// Off-white torn chit paper (#FFFDF3)
  static const Color paperWhite = Color(0xFFFFFDF3);
  static const Color cardCream = Color(0xFFFFFDF3); // backwards compatibility

  /// Notebook blue ruling line (#B8CFE3)
  static const Color blueRuling = Color(0xFFB8CFE3);

  /// Notebook red margin line (#D58A82)
  static const Color redMargin = Color(0xFFD3483E);

  /// Ballpoint blue ink (#1B2A6B)
  static const Color ballpointBlue = Color(0xFF1B2A6B);

  /// Green pencil fill (#C2E7C6)
  static const Color pencilGreenFill = Color(0xFFC2E7C6);

  /// Blue pencil fill (#BACDF5)
  static const Color pencilBlueFill = Color(0xFFBACDF5);

  /// Red pen ink (#D3483E)
  static const Color redInk = Color(0xFFD3483E);

  /// Yellow pencil fill (#F9E8B6)
  static const Color pencilYellowFill = Color(0xFFF9E8B6);

  /// Ink black (#29251F)
  static const Color inkBlack = Color(0xFF29251F);
  static const Color darkBrown = Color(0xFF29251F); // backwards compatibility

  /// Pen green (#315C3A)
  static const Color penGreen = Color(0xFF315C3A);
  static const Color leafGreen = Color(0xFF315C3A); // backwards compatibility

  /// Muted terracotta (#A94A32)
  static const Color terracotta = Color(0xFFA94A32);

  /// Pencil grey (#77716A)
  static const Color pencilGrey = Color(0xFF77716A);

  /// Turmeric yellow highlight (#D19A32)
  static const Color turmeric = Color(0xFFD19A32);

  /// Border Tint
  static const Color borderBrown = Color(0xFFB8CFE3);

  /// Role Specific Colors
  static const Color roleRaja = Color(0xFF243F72); // Ballpoint Blue
  static const Color roleRani = Color(0xFFA94A32); // Terracotta
  static const Color roleManthiri = Color(0xFF315C3A); // Pen Green
  static const Color roleSippai = Color(0xFF77716A); // Pencil Grey
  static const Color rolePolice = Color(0xFF29251F); // Ink Black
  static const Color roleThirudan = Color(0xFF8C3A24); // Muted Dark Red
}

class AppTypography {
  /// Primary Google Handwriting Font (Kalam) for Ballpoint Pen Game Headers & Titles
  static TextStyle handwrittenTitle({
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w900,
    Color color = AppColors.ballpointBlue,
    double letterSpacing = 2.0,
  }) {
    return GoogleFonts.kalam(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Secondary Google Handwriting Font (Caveat) for Subtitles & Pen Notes
  static TextStyle handwrittenSubtle({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.terracotta,
    double letterSpacing = 1.2,
  }) {
    return GoogleFonts.caveat(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Google Handwriting Font (Patrick Hand) for Player Names & Input Labels
  static TextStyle handwrittenBody({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.inkBlack,
    double letterSpacing = 0.5,
  }) {
    return GoogleFonts.patrickHand(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle displayTitle = GoogleFonts.kalam(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: AppColors.inkBlack,
    letterSpacing: 1.5,
  );

  static TextStyle sectionTitle = GoogleFonts.kalam(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.inkBlack,
    letterSpacing: 0.8,
  );

  static TextStyle body = GoogleFonts.patrickHand(
    fontSize: 15,
    color: AppColors.inkBlack,
    fontWeight: FontWeight.w600,
  );

  static TextStyle caption = GoogleFonts.caveat(
    fontSize: 14,
    color: AppColors.pencilGrey,
    fontWeight: FontWeight.w600,
  );

  static TextStyle penNote = GoogleFonts.caveat(
    fontSize: 16,
    color: AppColors.ballpointBlue,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.italic,
  );
}

class AppDecorations {
  static BoxDecoration traditionalCard({
    Color backgroundColor = AppColors.paperWhite,
    Color borderColor = AppColors.blueRuling,
    double borderWidth = 1.2,
    double borderRadius = 4.0,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 6,
          spreadRadius: 1,
          offset: Offset(1, 3),
        ),
      ],
    );
  }
}

