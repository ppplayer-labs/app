import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/core/network_outputs/cast/cast_platform_client.dart';

void main() {
  test(
    'desktop native Cast client does not subscribe to a mobile channel',
    () async {
      expect(await NativeCastPlatformClient().events.toList(), isEmpty);
    },
    skip: Platform.isAndroid || Platform.isIOS,
  );
}
