import 'package:flutter/material.dart';
import '../utils/responsive.dart';

/// Enhanced theme with responsive design support
class ResponsiveTheme {
  static ThemeData buildLightTheme(BuildContext context) {
    final base = ThemeData.light();
    
    return base.copyWith(
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      // Responsive typography
      textTheme: _buildResponsiveTextTheme(context, base.textTheme),
      
      // Enhanced app bar theme
      appBarTheme: AppBarThemeData(
        toolbarHeight: ResponsiveUtils.getSpacing(context, SpacingSize.xl) * 2,
        titleTextStyle: TextStyle(
          fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.title),
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(
          size: ResponsiveUtils.getIconSize(context, IconSizeType.medium),
        ),
      ),
      
      // Enhanced card theme
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, BorderRadiusSize.medium),
          ),
        ),
        elevation: 2,
      ),
      
      // Enhanced elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(
            double.infinity,
            ResponsiveUtils.getButtonHeight(context),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, BorderRadiusSize.small),
            ),
          ),
          textStyle: TextStyle(
            fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.body),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Enhanced input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: EdgeInsets.all(
          ResponsiveUtils.getSpacing(context, SpacingSize.md),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, BorderRadiusSize.small),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, BorderRadiusSize.small),
          ),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, BorderRadiusSize.small),
          ),
          borderSide: const BorderSide(color: Color(0xFFE65100), width: 2),
        ),
      ),
      
      // Enhanced bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.caption),
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.caption),
        ),
        selectedIconTheme: IconThemeData(
          size: ResponsiveUtils.getIconSize(context, IconSizeType.medium),
        ),
        unselectedIconTheme: IconThemeData(
          size: ResponsiveUtils.getIconSize(context, IconSizeType.medium),
        ),
      ),
      
      // Enhanced snackbar theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, BorderRadiusSize.small),
          ),
        ),
        contentTextStyle: TextStyle(
          fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.body),
        ),
      ),
      
      // Enhanced dialog theme
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, BorderRadiusSize.large),
          ),
        ),
        titleTextStyle: TextStyle(
          fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.title),
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        contentTextStyle: TextStyle(
          fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.body),
          color: Colors.black87,
        ),
      ),
    );
  }
  
  static TextTheme _buildResponsiveTextTheme(BuildContext context, TextTheme base) {
    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.headline),
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.title),
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.subtitle),
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.title),
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.subtitle),
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.body),
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.body),
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.body),
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.caption),
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.body),
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.caption),
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.caption),
      ),
    );
  }
}

/// Responsive spacing constants
class ResponsiveSpacing {
  static double xs(BuildContext context) => ResponsiveUtils.getSpacing(context, SpacingSize.xs);
  static double sm(BuildContext context) => ResponsiveUtils.getSpacing(context, SpacingSize.sm);
  static double md(BuildContext context) => ResponsiveUtils.getSpacing(context, SpacingSize.md);
  static double lg(BuildContext context) => ResponsiveUtils.getSpacing(context, SpacingSize.lg);
  static double xl(BuildContext context) => ResponsiveUtils.getSpacing(context, SpacingSize.xl);
}

/// Responsive typography shortcuts
class ResponsiveText {
  static double caption(BuildContext context) => ResponsiveUtils.getFontSize(context, FontSizeType.caption);
  static double body(BuildContext context) => ResponsiveUtils.getFontSize(context, FontSizeType.body);
  static double subtitle(BuildContext context) => ResponsiveUtils.getFontSize(context, FontSizeType.subtitle);
  static double title(BuildContext context) => ResponsiveUtils.getFontSize(context, FontSizeType.title);
  static double headline(BuildContext context) => ResponsiveUtils.getFontSize(context, FontSizeType.headline);
}

/// Responsive icon sizes
class ResponsiveIcons {
  static double small(BuildContext context) => ResponsiveUtils.getIconSize(context, IconSizeType.small);
  static double medium(BuildContext context) => ResponsiveUtils.getIconSize(context, IconSizeType.medium);
  static double large(BuildContext context) => ResponsiveUtils.getIconSize(context, IconSizeType.large);
  static double xl(BuildContext context) => ResponsiveUtils.getIconSize(context, IconSizeType.xl);
}