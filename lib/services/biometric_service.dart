import 'package:flutter/services.dart';

class BiometricService {
  static const MethodChannel _channel =
      MethodChannel('com.naveenmanickam.daypilot/biometrics');

  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> authenticate({required String reason}) async {
    try {
      return await _channel.invokeMethod<bool>(
            'authenticate',
            <String, Object>{'reason': reason},
          ) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
