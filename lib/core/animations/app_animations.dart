/// Animation curves and durations for Skilloka
import 'package:flutter/material.dart';

class AppAnimations {
  AppAnimations._();

  // Durations
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 600);
  static const Duration shimmer = Duration(milliseconds: 1200);
  static const Duration carousel = Duration(seconds: 5);

  // Curves
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve pageTransition = Curves.easeOutCubic;
  static const Curve buttonPress = Curves.easeInOut;
  static const Curve fadeIn = Curves.easeIn;
  static const Curve fadeOut = Curves.easeOut;
  static const Curve bounce = Curves.elasticOut;
  static const Curve overshoot = Curves.easeOutBack;
  static const Curve smooth = Curves.fastOutSlowIn;

  // Button Press Animation Values
  static const double buttonPressScale = 0.98;
  static const double cardPressScale = 0.98;
  static const double cardElevationPressed = 2.0;
  static const double cardElevationDefault = 8.0;

  // Page Transition
  static const Offset slideInFromRight = Offset(1.0, 0.0);
  static const Offset slideInFromBottom = Offset(0.0, 1.0);
  static const Offset slideInFromLeft = Offset(-1.0, 0.0);

  // Shared Element Hero Tag Prefixes
  static const String heroTagCourse = 'course_';
  static const String heroTagLPK = 'lpk_';
  static const String heroTagImage = 'image_';

  // Staggered Animation Delays
  static Duration staggerDelay(int index) {
    return Duration(milliseconds: 50 * index);
  }

  // Animation Builders
  static Widget fadeTransitionBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }

  static Widget slideUpTransitionBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: slideInFromBottom,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: pageTransition)),
      child: child,
    );
  }

  static Widget slideRightTransitionBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: slideInFromRight,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: pageTransition)),
      child: child,
    );
  }

  // Success Animation Constants
  static const Duration checkmarkDraw = Duration(milliseconds: 600);
  static const Duration confettiBurst = Duration(seconds: 2);

  // Pull to Refresh
  static const Duration pullToRefresh = Duration(milliseconds: 800);
  static const Curve pullToRefreshCurve = Curves.elasticOut;

  // Number Rolling Animation
  static const Duration numberRoll = Duration(milliseconds: 500);

  // Parallax Effect
  static const double parallaxFactor = 0.3;
}

/// Extension for easy animation application
extension AnimatedContainerDefaults on AnimatedContainer {
  static AnimatedContainer withDefaults({
    required Widget child,
    Duration? duration,
    Curve? curve,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Decoration? decoration,
    AlignmentGeometry? alignment,
    BoxConstraints? constraints,
    Matrix4? transform,
  }) {
    return AnimatedContainer(
      duration: duration ?? AppAnimations.medium,
      curve: curve ?? AppAnimations.defaultCurve,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: decoration,
      alignment: alignment,
      constraints: constraints,
      transform: transform,
      child: child,
    );
  }
}
