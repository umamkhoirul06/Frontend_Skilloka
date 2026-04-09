/// Security checker for root/jailbreak detection
import 'package:flutter/foundation.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import '../error/failures.dart';

abstract class SecurityChecker {
  Future<bool> isDeviceSecure();
  Future<SecurityFailure?> checkDeviceSecurity();
}

class SecurityCheckerImpl implements SecurityChecker {
  @override
  Future<bool> isDeviceSecure() async {
    // Skip security check in debug mode
    if (kDebugMode) return true;

    try {
      final isJailbroken = await FlutterJailbreakDetection.jailbroken;
      return !isJailbroken;
    } catch (e) {
      // If check fails, assume device is secure
      return true;
    }
  }

  @override
  Future<SecurityFailure?> checkDeviceSecurity() async {
    if (kDebugMode) return null;

    try {
      final isJailbroken = await FlutterJailbreakDetection.jailbroken;
      if (isJailbroken) {
        return SecurityFailure.rootedDevice();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Mixin for screens that need security check
mixin SecurityCheckMixin {
  Future<void> performSecurityCheck() async {
    final checker = SecurityCheckerImpl();
    final failure = await checker.checkDeviceSecurity();
    if (failure != null) {
      throw failure;
    }
  }
}
