import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// CONSTANTE DE POLICE GLOBALE
/// ---------------------------------------------------------------------------
const String kAppFontFamily = 'Google Sans';

/// ---------------------------------------------------------------------------
/// COULEURS GLOBALES (Fluent 2 Windows Desktop + Direction cresc/accent)
/// ---------------------------------------------------------------------------
class AppColors {
  // Arrière-plans & Surfaces de base (Préservation stricte des clés)
  static const Color bg = Color(0xFFF3F4F6); // Fond canvas doux (style Windows 11 / Mica)
  static const Color surface = Color(0xFFFFFFFF); // Blanc pur pour cartes et conteneurs
  static const Color cardBg = Color(0xFFFFFFFF); // Surface blanche nette (vs gris terne)
  static const Color surfaceMuted = Color(0xFFF8F9FA); // Fond d'inputs & zones secondaires
  static const Color border = Color(0x14000000); // Bordure ultra fine (8% noir)

  // Nouveaux tokens de surfaces Windows Desktop
  static const Color sidebarBg = Color(0xFFFAFAFA);
  static const Color cardBorder = Color(0x0F000000); // 6% d'opacité pour bordures de carte
  static const Color cardHoverBorder = Color(0x24000000);

  // Bleu Signature & Accents Windows Fluent
  static const Color primary = Color(0xFF0067C0); // Bleu Windows authentique & équilibré
  static const Color primaryHover = Color(0xFF1979CA);
  static const Color primaryActive = Color(0xFF005A9E);
  static const Color primarySubtle = Color(0xFFE8F2FB); // Fond de sélection d'onglet / pill
  static const Color heroDark = Color(0xFF152A68);
  static const Color heroGradientStart = Color(0xFF162D74);
  static const Color heroGradientEnd = Color(0xFF2854D8);

  // Typographie & Contrastes (Hiérarchie visuelle stricte)
  static const Color textPrimary = Color(0xFF1B1B1B); // Noir d'encre Windows 11
  static const Color textSecondary = Color(0xFF4A4A4A);
  static const Color textMuted = Color(0xFF6B7280); // Gris neutre lisible
  static const Color textSubtle = Color(0xFF9CA3AF); // Métadonnées & placeholders
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // États fonctionnels
  static const Color success = Color(0xFF107C41); // Vert Windows standard
  static const Color danger = Color(0xFFC42B1C); // Rouge d'alerte Windows
  static const Color warning = Color(0xFFBC4B09);
  static const Color info = Color(0xFF0067C0);

  // Gamme Pastel Signature (extraite des cartes de la référence visuelle)
  static const Color pastelBlue = Color(0xFFE0EDFF);
  static const Color pastelGreen = Color(0xFFDCF5E8);
  static const Color pastelPeach = Color(0xFFFFECE5);
  static const Color pastelLavender = Color(0xFFECEBFA);
  static const Color pastelSky = Color(0xFFE3F3FD);
}

/// ---------------------------------------------------------------------------
/// RAYONS D'ARRONDI (Standard Fluent 2 Desktop)
/// ---------------------------------------------------------------------------
class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0; // Standard cartes de la référence
  static const double lg = 16.0; // Grandes cartes "Devices"
  static const double xl = 24.0;
  static const double pill = 999.0;

  static BorderRadius get radiusXs => BorderRadius.circular(xs);
  static BorderRadius get radiusSm => BorderRadius.circular(sm);
  static BorderRadius get radiusMd => BorderRadius.circular(md);
  static BorderRadius get radiusLg => BorderRadius.circular(lg);
  static BorderRadius get radiusXl => BorderRadius.circular(xl);
  static BorderRadius get radiusPill => BorderRadius.circular(pill);
}

/// ---------------------------------------------------------------------------
/// OMBRES PORTÉES (Micro-ombres desktop douces, anti-lourdeur)
/// ---------------------------------------------------------------------------
class AppShadows {
  // Ombre subtile standard pour carte au repos
  static BoxShadow get soft => const BoxShadow(
    color: Color(0x0A000000), // 4% noir
    blurRadius: 10,
    spreadRadius: 0,
    offset: Offset(0, 2),
  );

  // Ombre au survol d'une carte interactive
  static BoxShadow get hover => const BoxShadow(
    color: Color(0x14000000), // 8% noir
    blurRadius: 20,
    spreadRadius: 0,
    offset: Offset(0, 8),
  );

  // Lueur d'accentuation discrète
  static BoxShadow get buttonGlow => const BoxShadow(
    color: Color(0x200067C0),
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  // Menu déroulant / Popup
  static BoxShadow get popover => const BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 28,
    spreadRadius: -2,
    offset: Offset(0, 12),
  );
}

//// ---------------------------------------------------------------------------
/// TYPOGRAPHIE (Google Sans - Calibrée sur 400, 500 et 700)
/// ---------------------------------------------------------------------------
class AppTypography {
  // Titres majeurs de sections
  static const TextStyle h1 = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.textPrimary,
    letterSpacing: -0.6,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static const TextStyle title = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
  );

  // Corps de texte
  static const TextStyle body = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 13.5,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.textPrimary,
    letterSpacing: 0,
    height: 1.45,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 13.5,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.textPrimary,
    letterSpacing: 0,
    height: 1.45,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.textMuted,
    letterSpacing: 0,
    height: 1.4,
  );

  // Éléments d'interface
  static const TextStyle label = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );

  static const TextStyle categoryPill = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );

  static const TextStyle priceTag = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 13.5,
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.primary,
    letterSpacing: -0.2,
  );

  static const TextStyle button = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  static const TextStyle link = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.primary,
    letterSpacing: 0.1,
  );
}
/// ---------------------------------------------------------------------------
/// EXTENSION THÈME FLUTTER (Intégration transparente avec MaterialApp)
/// ---------------------------------------------------------------------------
ThemeData buildFluentDesktopTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: kAppFontFamily,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.danger,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: AppRadius.radiusSm,
      ),
      textStyle: const TextStyle(
        fontFamily: kAppFontFamily,
        fontSize: 12,
        color: Colors.white,
      ),
      waitDuration: const Duration(milliseconds: 500),
    ),
  );
}