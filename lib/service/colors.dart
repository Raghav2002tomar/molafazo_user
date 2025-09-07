// // lib/theme/app_theme.dart
// import 'package:flutter/material.dart';
//
// class AppTheme {
//   // Brand seed colors
//   static const Color seedPrimary = Color(0xFF1E88E5); // Blue 600
//   static const Color seedSecondary = Color(0xFF00897B); // Teal 600
//   static const Color seedTertiary = Color(0xFFFF8A65); // Deep Orange 300 (promo)
//
//   // Optional: enable true black for dark surfaces (AMOLED)
//   static const bool useTrueBlackDark = false;
//
//   // Common typography and shapes
//   static const TextTheme _textTheme = TextTheme(
//     headlineLarge: TextStyle(fontWeight: FontWeight.w700),
//     headlineMedium: TextStyle(fontWeight: FontWeight.w700),
//     titleLarge: TextStyle(fontWeight: FontWeight.w600),
//     titleMedium: TextStyle(fontWeight: FontWeight.w600),
//     bodyLarge: TextStyle(fontWeight: FontWeight.w500),
//   );
//
//   static ThemeData light() {
//     final ColorScheme scheme = ColorScheme.fromSeed(
//       seedColor: seedPrimary,
//       primary: seedPrimary,
//       secondary: seedSecondary,
//       tertiary: seedTertiary,
//       brightness: Brightness.light,
//     );
//
//     return ThemeData(
//       useMaterial3: true,
//       brightness: Brightness.light,
//       colorScheme: scheme,
//       textTheme: _textTheme,
//       appBarTheme: AppBarTheme(
//         backgroundColor: scheme.surface,
//         foregroundColor: scheme.onSurface,
//         centerTitle: true,
//         elevation: 0,
//       ),
//       filledButtonTheme: FilledButtonThemeData(
//         style: FilledButton.styleFrom(
//           foregroundColor: scheme.onPrimary,
//           backgroundColor: scheme.primary,
//           minimumSize: const Size.fromHeight(48),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       ),
//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           foregroundColor: scheme.onPrimary,
//           backgroundColor: scheme.primary,
//           minimumSize: const Size.fromHeight(48),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       ),
//       outlinedButtonTheme: OutlinedButtonThemeData(
//         style: OutlinedButton.styleFrom(
//           foregroundColor: scheme.primary,
//           side: BorderSide(color: scheme.outline),
//           minimumSize: const Size.fromHeight(48),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       ),
//       inputDecorationTheme: InputDecorationTheme(
//         filled: true,
//         fillColor: scheme.surfaceContainerHighest,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: scheme.outlineVariant),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: scheme.outlineVariant),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: scheme.primary, width: 1.4),
//         ),
//       ),
//       chipTheme: ChipThemeData(
//         backgroundColor: scheme.surfaceContainerHigh,
//         selectedColor: scheme.secondaryContainer,
//         labelStyle: TextStyle(color: scheme.onSurface),
//         selectedShadowColor: scheme.shadow,
//       ),
//       // Use CardThemeData (not CardTheme)
//       cardTheme: CardThemeData(
//         color: scheme.surface,
//         margin: const EdgeInsets.all(8),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         elevation: 0.5,
//       ),
//       dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
//       snackBarTheme: SnackBarThemeData(
//         backgroundColor: scheme.inverseSurface,
//         contentTextStyle: TextStyle(color: scheme.onInverseSurface),
//         actionTextColor: scheme.tertiary,
//       ),
//       bottomNavigationBarTheme: BottomNavigationBarThemeData(
//         backgroundColor: scheme.surface,
//         selectedItemColor: scheme.primary,
//         unselectedItemColor: scheme.onSurfaceVariant,
//         type: BottomNavigationBarType.fixed,
//       ),
//       listTileTheme: ListTileThemeData(
//         iconColor: scheme.onSurfaceVariant,
//         selectedColor: scheme.primary,
//         selectedTileColor: scheme.secondaryContainer.withOpacity(0.24),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//       // Use DialogThemeData (not DialogTheme)
//       dialogTheme: DialogThemeData(
//         backgroundColor: scheme.surfaceContainerHighest,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       ),
//     );
//   }
//
//   static ThemeData dark() {
//     // Generate dark scheme from same seeds for consistent brand mapping
//     var scheme = ColorScheme.fromSeed(
//       seedColor: seedPrimary,
//       primary: seedPrimary,
//       secondary: seedSecondary,
//       tertiary: seedTertiary,
//       brightness: Brightness.dark,
//     );
//
//     if (useTrueBlackDark) {
//       scheme = scheme.copyWith(
//         surface: const Color(0xFF000000),
//         surfaceDim: const Color(0xFF000000),
//         surfaceBright: const Color(0xFF121212),
//         background: const Color(0xFF000000),
//         surfaceContainerLowest: const Color(0xFF000000),
//         surfaceContainerLow: const Color(0xFF0A0A0A),
//         surfaceContainer: const Color(0xFF0E0E0E),
//         surfaceContainerHigh: const Color(0xFF121212),
//         surfaceContainerHighest: const Color(0xFF151515),
//       );
//     }
//
//     return ThemeData(
//       useMaterial3: true,
//       brightness: Brightness.dark,
//       colorScheme: scheme,
//       textTheme: _textTheme,
//       appBarTheme: AppBarTheme(
//         backgroundColor: scheme.surface,
//         foregroundColor: scheme.onSurface,
//         centerTitle: true,
//         elevation: 0,
//       ),
//       filledButtonTheme: FilledButtonThemeData(
//         style: FilledButton.styleFrom(
//           foregroundColor: scheme.onPrimary,
//           backgroundColor: scheme.primary,
//           minimumSize: const Size.fromHeight(48),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       ),
//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           foregroundColor: scheme.onPrimary,
//           backgroundColor: scheme.primary,
//           minimumSize: const Size.fromHeight(48),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       ),
//       outlinedButtonTheme: OutlinedButtonThemeData(
//         style: OutlinedButton.styleFrom(
//           foregroundColor: scheme.primary,
//           side: BorderSide(color: scheme.outline),
//           minimumSize: const Size.fromHeight(48),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       ),
//       inputDecorationTheme: InputDecorationTheme(
//         filled: true,
//         fillColor: scheme.surfaceContainerHighest,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: scheme.outlineVariant),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: scheme.outlineVariant),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: scheme.primary, width: 1.4),
//         ),
//       ),
//       chipTheme: ChipThemeData(
//         backgroundColor: scheme.surfaceContainerHigh,
//         selectedColor: scheme.secondaryContainer,
//         labelStyle: TextStyle(color: scheme.onSurface),
//         selectedShadowColor: scheme.shadow,
//       ),
//       // Use CardThemeData (not CardTheme)
//       cardTheme: CardThemeData(
//         color: scheme.surface,
//         margin: const EdgeInsets.all(8),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         elevation: 0.3,
//       ),
//       dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
//       snackBarTheme: SnackBarThemeData(
//         backgroundColor: scheme.inverseSurface,
//         contentTextStyle: TextStyle(color: scheme.onInverseSurface),
//         actionTextColor: scheme.tertiary,
//       ),
//       bottomNavigationBarTheme: BottomNavigationBarThemeData(
//         backgroundColor: scheme.surface,
//         selectedItemColor: scheme.primary,
//         unselectedItemColor: scheme.onSurfaceVariant,
//         type: BottomNavigationBarType.fixed,
//       ),
//       listTileTheme: ListTileThemeData(
//         iconColor: scheme.onSurfaceVariant,
//         selectedColor: scheme.primary,
//         selectedTileColor: scheme.secondaryContainer.withOpacity(0.22),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//       // Use DialogThemeData (not DialogTheme)
//       dialogTheme: DialogThemeData(
//         backgroundColor: scheme.surfaceContainerHighest,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';

class AppTheme {
  // Brand seed colors
  static const Color seedPrimary = Color(0xFF1E88E5); // Blue 600
  static const Color seedSecondary = Color(0xFF00897B); // Teal 600
  static const Color seedTertiary = Color(0xFFFF8A65); // Deep Orange 300 (promo)

  // Optional: enable true black for dark surfaces (AMOLED)
  static const bool useTrueBlackDark = false;

  // Common typography and shapes: keep weights; let colors come from the theme
  static const TextTheme _textTheme = TextTheme(
    headlineLarge: TextStyle(fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontWeight: FontWeight.w500),
  );

  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seedPrimary,
      primary: seedPrimary,
      secondary: seedSecondary,
      tertiary: seedTertiary,
      brightness: Brightness.light,
    ); // Uses M3 roles including surfaceContainer* for depth [2]

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      textTheme: _textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: true,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: scheme.onPrimary,
          backgroundColor: scheme.primary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: scheme.onPrimary,
          backgroundColor: scheme.primary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.secondaryContainer,
        labelStyle: TextStyle(color: scheme.onSurface),
        selectedShadowColor: scheme.shadow,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0.5,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        actionTextColor: scheme.tertiary,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        selectedColor: scheme.primary,
        selectedTileColor: scheme.secondaryContainer.withOpacity(0.24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ); // ColorScheme is the source of truth in Material 3 [1]
  }

  static ThemeData dark() {
    var scheme = ColorScheme.fromSeed(
      seedColor: seedPrimary,
      primary: seedPrimary,
      secondary: seedSecondary,
      tertiary: seedTertiary,
      brightness: Brightness.dark,
    ); // From same seeds for consistent mapping in dark mode [2]

    if (useTrueBlackDark) {
      scheme = scheme.copyWith(
        surface: const Color(0xFF000000),
        surfaceDim: const Color(0xFF000000),
        surfaceBright: const Color(0xFF121212),
        background: const Color(0xFF000000), // deprecated, kept for older widgets
        surfaceContainerLowest: const Color(0xFF000000),
        surfaceContainerLow: const Color(0xFF0A0A0A),
        surfaceContainer: const Color(0xFF0E0E0E),
        surfaceContainerHigh: const Color(0xFF121212),
        surfaceContainerHighest: const Color(0xFF151515),
      ); // AMOLED “lights out” variant [1]
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      textTheme: _textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: true,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: scheme.onPrimary,
          backgroundColor: scheme.primary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: scheme.onPrimary,
          backgroundColor: scheme.primary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.secondaryContainer,
        labelStyle: TextStyle(color: scheme.onSurface),
        selectedShadowColor: scheme.shadow,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0.5,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        actionTextColor: scheme.tertiary,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        selectedColor: scheme.primary,
        selectedTileColor: scheme.secondaryContainer.withOpacity(0.22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ); // Material 3 dark roles and containers [1]
  }
}