import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de cores do aplicativo, inspirada no painel de instrumentos e na
/// oficina de uma motocicleta: âmbar de marcador de combustível, verde
/// musgo de sinalização "ok", ferrugem como alerta e tons de aço/asfalto
/// como neutros — em vez da paleta azul/roxo genérica de apps utilitários.
class CoresApp {
  CoresApp._();

  /// Âmbar do painel — cor de destaque principal (combustível, ações).
  static const ambarPainel = Color(0xFFE8A23A);

  /// Aço/teal profundo — cor de destaque secundária (manutenção, ícones).
  static const acoAsfalto = Color(0xFF2F4858);

  /// Grafite — neutro mais escuro, usado como fundo do tema escuro e do
  /// painel de instrumentos (que é sempre escuro, como um painel real).
  static const grafite = Color(0xFF1B1E22);
  static const grafiteClaro = Color(0xFF23262B);

  /// Neblina — neutro mais claro, fundo do tema claro.
  static const neblina = Color(0xFFEEF0F1);

  /// Ferrugem — vermelho de alerta (troca vencida, exclusão).
  static const ferrugem = Color(0xFFC1483B);

  /// Verde musgo — sinalização "em dia".
  static const verdeMusgo = Color(0xFF4C7A5E);
}

/// Constrói os [ThemeData] claro e escuro do aplicativo a partir da paleta
/// de [CoresApp], com tipografia e temas de componentes customizados para
/// fugir do visual padrão do Material Design.
class AppTheme {
  AppTheme._();

  static ThemeData claro() => _construir(_esquemaClaro());
  static ThemeData escuro() => _construir(_esquemaEscuro());

  static ColorScheme _esquemaClaro() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: CoresApp.ambarPainel,
      onPrimary: CoresApp.grafite,
      secondary: CoresApp.acoAsfalto,
      onSecondary: Colors.white,
      error: CoresApp.ferrugem,
      onError: Colors.white,
      surface: CoresApp.neblina,
      onSurface: CoresApp.grafiteClaro,
      surfaceContainerHighest: Color(0xFFE2E5E7),
      outline: Color(0xFFCDD2D5),
      outlineVariant: Color(0xFFDCDFE1),
      surfaceTint: Colors.transparent,
    );
  }

  static ColorScheme _esquemaEscuro() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFF0AD4E),
      onPrimary: CoresApp.grafite,
      secondary: Color(0xFF7FA3B3),
      onSecondary: CoresApp.grafite,
      error: Color(0xFFE2695A),
      onError: CoresApp.grafite,
      surface: CoresApp.grafite,
      onSurface: Color(0xFFEBEDEE),
      surfaceContainerHighest: Color(0xFF2A2E33),
      outline: Color(0xFF3A3F45),
      outlineVariant: Color(0xFF2F3338),
      surfaceTint: Colors.transparent,
    );
  }

  static ThemeData _construir(ColorScheme cs) {
    final corSuperficie = Color.alphaBlend(
      cs.onSurface.withOpacity(cs.brightness == Brightness.dark ? 0.04 : 0.035),
      cs.surface,
    );
    final radiusPadrao = BorderRadius.circular(10);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      textTheme: _construirTextTheme(cs),
      dividerColor: cs.outlineVariant,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.bigShouldersDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: cs.onSurface,
        ),
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      cardTheme: CardThemeData(
        color: corSuperficie,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radiusPadrao,
          side: BorderSide(color: cs.outline, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: corSuperficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: cs.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: radiusPadrao),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          side: BorderSide(color: cs.outline),
          shape: RoundedRectangleBorder(borderRadius: radiusPadrao),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.onSurface,
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        extendedTextStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: corSuperficie,
        selectedColor: cs.primary.withOpacity(0.22),
        side: BorderSide(color: cs.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 13, color: cs.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: corSuperficie,
        border: OutlineInputBorder(borderRadius: radiusPadrao, borderSide: BorderSide(color: cs.outline)),
        enabledBorder: OutlineInputBorder(borderRadius: radiusPadrao, borderSide: BorderSide(color: cs.outline)),
        focusedBorder: OutlineInputBorder(borderRadius: radiusPadrao, borderSide: BorderSide(color: cs.primary, width: 2)),
        labelStyle: GoogleFonts.manrope(color: cs.onSurface.withOpacity(0.7)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? cs.primary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? cs.primary.withOpacity(0.4) : null,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: corSuperficie,
        indicatorColor: cs.primary.withOpacity(0.22),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? cs.onSurface : cs.onSurface.withOpacity(0.6),
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? cs.primary : cs.onSurface.withOpacity(0.6),
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: corSuperficie,
        indicatorColor: cs.primary.withOpacity(0.22),
        selectedIconTheme: IconThemeData(color: cs.primary),
        unselectedIconTheme: IconThemeData(color: cs.onSurface.withOpacity(0.6)),
        selectedLabelTextStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: cs.onSurface),
        unselectedLabelTextStyle: GoogleFonts.manrope(color: cs.onSurface.withOpacity(0.6)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: cs.onSurface.withOpacity(0.7),
        textColor: cs.onSurface,
      ),
      dividerTheme: DividerThemeData(color: cs.outlineVariant, thickness: 1, space: 1),
    );
  }

  static TextTheme _construirTextTheme(ColorScheme cs) {
    final cor = cs.onSurface;
    return TextTheme(
      displayLarge: GoogleFonts.bigShouldersDisplay(fontSize: 56, fontWeight: FontWeight.w700, color: cor, height: 1.0),
      displayMedium: GoogleFonts.bigShouldersDisplay(fontSize: 40, fontWeight: FontWeight.w700, color: cor, height: 1.0),
      displaySmall: GoogleFonts.bigShouldersDisplay(fontSize: 32, fontWeight: FontWeight.w700, color: cor, height: 1.0),
      headlineLarge: GoogleFonts.bigShouldersDisplay(fontSize: 30, fontWeight: FontWeight.w600, color: cor),
      headlineMedium: GoogleFonts.bigShouldersDisplay(fontSize: 24, fontWeight: FontWeight.w600, color: cor),
      titleLarge: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700, color: cor),
      titleMedium: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: cor),
      titleSmall: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: cor),
      bodyLarge: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w400, color: cor),
      bodyMedium: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w400, color: cor),
      bodySmall: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w400, color: cor.withOpacity(0.7)),
      labelLarge: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: cor),
      labelMedium: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: cor),
      labelSmall: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: cor.withOpacity(0.7)),
    );
  }
}
