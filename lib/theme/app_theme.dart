import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color debit;
  final Color debitBg;
  final Color credit;
  final Color creditBg;
  final Color textTertiary;
  final Color cardBorder;
  final Gradient primaryGradient;
  final Gradient surfaceGradient;

  const AppThemeExtension({
    required this.debit,
    required this.debitBg,
    required this.credit,
    required this.creditBg,
    required this.textTertiary,
    required this.cardBorder,
    required this.primaryGradient,
    required this.surfaceGradient,
  });

  @override
  AppThemeExtension copyWith({
    Color? debit,
    Color? debitBg,
    Color? credit,
    Color? creditBg,
    Color? textTertiary,
    Color? cardBorder,
    Gradient? primaryGradient,
    Gradient? surfaceGradient,
  }) {
    return AppThemeExtension(
      debit: debit ?? this.debit,
      debitBg: debitBg ?? this.debitBg,
      credit: credit ?? this.credit,
      creditBg: creditBg ?? this.creditBg,
      textTertiary: textTertiary ?? this.textTertiary,
      cardBorder: cardBorder ?? this.cardBorder,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      surfaceGradient: surfaceGradient ?? this.surfaceGradient,
    );
  }

  @override
  AppThemeExtension lerp(AppThemeExtension? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      debit: Color.lerp(debit, other.debit, t)!,
      debitBg: Color.lerp(debitBg, other.debitBg, t)!,
      credit: Color.lerp(credit, other.credit, t)!,
      creditBg: Color.lerp(creditBg, other.creditBg, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      primaryGradient: other.primaryGradient,
      surfaceGradient: other.surfaceGradient,
    );
  }
}

extension AppThemeX on BuildContext {
  AppThemeExtension get appColors =>
      Theme.of(this).extension<AppThemeExtension>()!;
}

class AppTheme {
  static const inkDark = Color(0xFF2C2416);
  static const inkFaded = Color(0xFF5A5044);
  static const parchment = Color(0xFFF4EFDF);
  static const parchmentLight = Color(0xFFFFFDF5);
  static const ruled = Color(0xFFD4C9B5);
  static const inkRed = Color(0xFF8B2500);
  static const inkBlue = Color(0xFF1B3A5C);

  static ThemeData light() {
    final base = ThemeData.light();
    final textTheme = GoogleFonts.loraTextTheme(base.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: inkDark,
        onPrimary: parchmentLight,
        primaryContainer: parchment,
        onPrimaryContainer: inkDark,
        secondary: inkFaded,
        onSecondary: parchmentLight,
        secondaryContainer: parchment,
        surface: parchment,
        onSurface: inkDark,
        onSurfaceVariant: inkFaded,
        outline: ruled,
        outlineVariant: Color(0xFFE8E0CC),
        error: inkRed,
        onError: parchmentLight,
      ),
      scaffoldBackgroundColor: parchmentLight,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: parchmentLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: inkDark,
          fontSize: 20,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: inkDark),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: parchment,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: ruled),
        backgroundColor: parchment,
        selectedColor: inkDark,
        labelStyle: textTheme.bodySmall,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: parchment,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ruled),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ruled),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: inkDark, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: inkFaded,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
        dragHandleColor: ruled,
        backgroundColor: parchmentLight,
      ),
      dividerTheme: const DividerThemeData(
        color: ruled,
        thickness: 0.5,
        space: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: inkDark,
          foregroundColor: parchmentLight,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: inkDark,
          textStyle: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: parchmentLight,
        surfaceTintColor: Colors.transparent,
      ),
      extensions: const [
        AppThemeExtension(
          debit: inkRed,
          debitBg: Color(0xFFF5E6E0),
          credit: inkBlue,
          creditBg: Color(0xFFE0E8F0),
          textTertiary: inkFaded,
          cardBorder: ruled,
          primaryGradient: LinearGradient(
            colors: [inkDark, Color(0xFF4A3C2A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          surfaceGradient: LinearGradient(
            colors: [parchment, Color(0xFFEDE6D4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ],
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark();
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

    const scaffoldBg = Color(0xFF09090F);
    const surfaceColor = Color(0xFF12121E);
    const surfaceVariant = Color(0xFF1A1A2E);
    const borderColor = Color(0xFF2A2A3E);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF818CF8),
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF2A2660),
        onPrimaryContainer: Color(0xFFC7D2FE),
        secondary: Color(0xFF94A3B8),
        onSecondary: Color(0xFF0F172A),
        secondaryContainer: Color(0xFF1E1E2E),
        surface: surfaceColor,
        onSurface: Color(0xFFF1F5F9),
        onSurfaceVariant: Color(0xFF8890A5),
        outline: borderColor,
        outlineVariant: Color(0xFF3A3A50),
        error: Color(0xFFFB7185),
        onError: Color(0xFF450A0A),
      ),
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFFF1F5F9),
          fontSize: 20,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: Color(0xFFF1F5F9)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: borderColor),
        backgroundColor: surfaceColor,
        selectedColor: const Color(0xFF818CF8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF5A5A72),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: Color(0xFF3A3A50),
        backgroundColor: surfaceColor,
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF818CF8),
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF818CF8),
          textStyle: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
      ),
      extensions: const [
        AppThemeExtension(
          debit: Color(0xFFFB7185),
          debitBg: Color(0xFF2A1520),
          credit: Color(0xFF34D399),
          creditBg: Color(0xFF0A2920),
          textTertiary: Color(0xFF5A5A72),
          cardBorder: Color(0xFF2A2A3E),
          primaryGradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          surfaceGradient: LinearGradient(
            colors: [Color(0xFF1A1440), Color(0xFF12121E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ],
    );
  }
}
