import 'package:flutter/material.dart';

/// Responsive utility class for adaptive UI across all platforms
class ResponsiveUtils {
  /// Device size classifications
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  /// Get current device type
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Get responsive spacing based on device type
  static double getSpacing(BuildContext context, SpacingSize size) {
    final deviceType = getDeviceType(context);
    switch (size) {
      case SpacingSize.xs:
        return deviceType == DeviceType.mobile ? 4 : 6;
      case SpacingSize.sm:
        return deviceType == DeviceType.mobile ? 8 : 12;
      case SpacingSize.md:
        return deviceType == DeviceType.mobile ? 16 : 20;
      case SpacingSize.lg:
        return deviceType == DeviceType.mobile ? 24 : 32;
      case SpacingSize.xl:
        return deviceType == DeviceType.mobile ? 32 : 48;
    }
  }

  /// Get responsive font size
  static double getFontSize(BuildContext context, FontSizeType type) {
    final deviceType = getDeviceType(context);
    final scaleFactor = deviceType == DeviceType.mobile ? 1.0 : 1.1;
    
    switch (type) {
      case FontSizeType.caption:
        return 12 * scaleFactor;
      case FontSizeType.body:
        return 14 * scaleFactor;
      case FontSizeType.subtitle:
        return 16 * scaleFactor;
      case FontSizeType.title:
        return 18 * scaleFactor;
      case FontSizeType.headline:
        return 24 * scaleFactor;
    }
  }

  /// Get responsive grid columns
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 1; // Very small phones
    if (width < mobileBreakpoint) return 2; // Mobile
    if (width < tabletBreakpoint) return 3; // Tablet portrait
    if (width < desktopBreakpoint) return 4; // Tablet landscape
    return 5; // Desktop
  }

  /// Get responsive container width
  static double getContainerWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return width;
    if (width < tabletBreakpoint) return width * 0.9;
    return 800; // Max width for desktop
  }

  /// Get responsive aspect ratio for cards
  static double getCardAspectRatio(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 1.2; // Slightly taller on mobile
      case DeviceType.tablet:
        return 1.4; // More rectangular on tablet
      case DeviceType.desktop:
        return 1.6; // Wide on desktop
    }
  }

  /// Get safe padding considering notch and system UI
  static EdgeInsets getSafePadding(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final spacing = getSpacing(context, SpacingSize.md);
    
    return EdgeInsets.only(
      left: spacing,
      right: spacing,
      top: padding.top + getSpacing(context, SpacingSize.sm),
      bottom: padding.bottom + getSpacing(context, SpacingSize.sm),
    );
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context, IconSizeType type) {
    final deviceType = getDeviceType(context);
    final scaleFactor = deviceType == DeviceType.mobile ? 1.0 : 1.2;
    
    switch (type) {
      case IconSizeType.small:
        return 16 * scaleFactor;
      case IconSizeType.medium:
        return 24 * scaleFactor;
      case IconSizeType.large:
        return 32 * scaleFactor;
      case IconSizeType.xl:
        return 48 * scaleFactor;
    }
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get responsive button height
  static double getButtonHeight(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 48;
      case DeviceType.tablet:
        return 52;
      case DeviceType.desktop:
        return 56;
    }
  }

  /// Get responsive border radius
  static double getBorderRadius(BuildContext context, BorderRadiusSize size) {
    final deviceType = getDeviceType(context);
    final scaleFactor = deviceType == DeviceType.mobile ? 1.0 : 1.2;
    
    switch (size) {
      case BorderRadiusSize.small:
        return 8 * scaleFactor;
      case BorderRadiusSize.medium:
        return 12 * scaleFactor;
      case BorderRadiusSize.large:
        return 16 * scaleFactor;
      case BorderRadiusSize.xl:
        return 24 * scaleFactor;
    }
  }
}

/// Responsive widget wrapper
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;
  
  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);
    return builder(context, deviceType);
  }
}

/// Safe scroll wrapper to prevent overflow
class SafeScrollView extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  
  const SafeScrollView({
    super.key,
    required this.child,
    this.padding,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: physics ?? const ClampingScrollPhysics(),
          padding: padding ?? ResponsiveUtils.getSafePadding(context),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 
                (padding?.vertical ?? ResponsiveUtils.getSafePadding(context).vertical),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Responsive grid widget
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double? aspectRatio;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;
  
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.aspectRatio,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveUtils.getGridColumns(context);
    final spacing = ResponsiveUtils.getSpacing(context, SpacingSize.sm);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: aspectRatio ?? ResponsiveUtils.getCardAspectRatio(context),
        mainAxisSpacing: mainAxisSpacing ?? spacing,
        crossAxisSpacing: crossAxisSpacing ?? spacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Constrained container for responsive layouts
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool center;
  
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    final width = ResponsiveUtils.getContainerWidth(context);
    final defaultPadding = ResponsiveUtils.getSafePadding(context);
    
    return Container(
      width: double.infinity,
      padding: padding ?? defaultPadding,
      child: center
          ? Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width),
                child: child,
              ),
            )
          : ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width),
              child: child,
            ),
    );
  }
}

enum DeviceType { mobile, tablet, desktop }
enum SpacingSize { xs, sm, md, lg, xl }
enum FontSizeType { caption, body, subtitle, title, headline }
enum IconSizeType { small, medium, large, xl }
enum BorderRadiusSize { small, medium, large, xl }