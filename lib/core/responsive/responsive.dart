import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

abstract final class Breakpoints {
  static const double tablet = 720;
  static const double desktop = 1080;
  static const double maxContent = 1240;
}

extension ResponsiveContext on BuildContext {
  Size get _size => MediaQuery.sizeOf(this);
  double get screenWidth => _size.width;
  double get screenHeight => _size.height;

  DeviceType get device {
    final w = screenWidth;
    if (w >= Breakpoints.desktop) return DeviceType.desktop;
    if (w >= Breakpoints.tablet) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  bool get isMobile => device == DeviceType.mobile;
  bool get isTablet => device == DeviceType.tablet;
  bool get isDesktop => device == DeviceType.desktop;

  /// The custom magnetic cursor + hover affordances only make sense with a
  /// pointer and enough room, so we gate them on width.
  bool get usePointerInteractions => screenWidth >= Breakpoints.desktop;

  /// Respect the OS "reduce motion" accessibility setting.
  bool get reduceMotion => MediaQuery.of(this).disableAnimations;

  /// Horizontal page gutters that grow with the viewport.
  double get pageGutter {
    switch (device) {
      case DeviceType.desktop:
        return 96;
      case DeviceType.tablet:
        return 56;
      case DeviceType.mobile:
        return 24;
    }
  }

  /// Pick a value per device with sensible fallbacks.
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    switch (device) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }
}
