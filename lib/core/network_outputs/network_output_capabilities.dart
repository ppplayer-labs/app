import 'dart:io';
import 'package:flutter/services.dart';

class NetworkOutputsCapabilities {
  final bool dlnaAvailable;
  final bool googleCastAvailable;
  final bool airPlayPickerAvailable;

  const NetworkOutputsCapabilities({
    required this.dlnaAvailable,
    required this.googleCastAvailable,
    this.airPlayPickerAvailable = false,
  });

  static Future<NetworkOutputsCapabilities> resolve() async {
    if (Platform.isIOS) {
      try {
        final result = await const MethodChannel(
          'com.ppplayer.app/network_outputs',
        ).invokeMethod('getPlatformCapabilities');
        final map = result as Map?;
        return NetworkOutputsCapabilities(
          dlnaAvailable: map?['dlnaDiscoveryAvailable'] == true,
          googleCastAvailable: map?['googleCastAvailable'] == true,
          airPlayPickerAvailable: map?['airPlayPickerAvailable'] == true,
        );
      } catch (_) {}
      return const NetworkOutputsCapabilities(
        dlnaAvailable: false,
        googleCastAvailable: false,
      );
    }
    if (Platform.isAndroid) {
      return const NetworkOutputsCapabilities(
        dlnaAvailable: true,
        googleCastAvailable: true,
      );
    }
    if (Platform.isMacOS) {
      return const NetworkOutputsCapabilities(
        dlnaAvailable: true,
        googleCastAvailable: true,
      );
    }
    return const NetworkOutputsCapabilities(
      dlnaAvailable: true,
      googleCastAvailable: false,
    );
  }
}
