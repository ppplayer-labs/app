import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/shared/widgets/pp_image.dart';

void main() {
  test('file artwork preserves spaces and Unicode in URI', () {
    final file = File('/tmp/album art ç.png');
    final provider = PPImage.getImageProvider(file.uri.toString()) as FileImage;
    expect(provider.file.path, file.path);
  });
  testWidgets('opaque locator never reaches the HTTP image cache', (
    tester,
  ) async {
    expect(PPImage.getImageProvider('Ym9va21hcms='), isA<AssetImage>());
    await tester.pumpWidget(
      const MaterialApp(home: PPImage(imageUrl: 'Ym9va21hcms=')),
    );
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
