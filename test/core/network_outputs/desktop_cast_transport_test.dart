import 'dart:async';
import 'dart:convert';
import 'dart:io';

// Wire-level tests use the pinned package's framing model, as the adapter does.
// ignore: implementation_imports
import 'package:dart_cast/src/protocols/chromecast/castv2_channel.dart';
// ignore: implementation_imports
import 'package:dart_cast/src/protocols/chromecast/proto/cast_channel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/core/network_outputs/cast/desktop_cast_transport.dart';

void main() {
  test(
    'real TLS transport sends protobuf and handles fragmented/coalesced receiver frames',
    () async {
      final context = SecurityContext()
        ..useCertificateChain('test/fixtures/cast/localhost-cert.pem')
        ..usePrivateKey('test/fixtures/cast/localhost-key.pem');
      final server = await SecureServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
        context,
      );
      final accepted = Completer<SecureSocket>();
      final listener = server.listen(accepted.complete);
      final transport = CastV2DesktopTransport();
      addTearDown(() async {
        await transport.close();
        await listener.cancel();
        await server.close();
      });
      await transport.connect('127.0.0.1', server.port);
      final socket = await accepted.future;
      addTearDown(socket.destroy);
      final received = CastV2Channel.parseMessages(socket).first;
      transport.send('urn:x-cast:com.google.cast.media', 'receiver-transport', {
        'type': 'PAUSE',
        'requestId': 1,
        'mediaSessionId': 7,
      });
      final command = await received.timeout(const Duration(seconds: 2));
      expect(command.sourceId, 'ppplayer-sender');
      expect(command.destinationId, 'receiver-transport');
      expect(jsonDecode(command.payloadUtf8)['mediaSessionId'], 7);
      List<int> frame(int requestId) => CastV2Channel.frameMessage(
        CastMessage()
          ..protocolVersion = CastMessage_ProtocolVersion.CASTV2_1_0
          ..sourceId = 'receiver-transport'
          ..destinationId = 'ppplayer-sender'
          ..namespace_ = 'urn:x-cast:com.google.cast.media'
          ..payloadType = CastMessage_PayloadType.STRING
          ..payloadUtf8 = jsonEncode({
            'type': 'MEDIA_STATUS',
            'requestId': requestId,
            'status': [],
          }),
      );
      final messages = transport.messages.take(2).toList();
      final first = frame(1);
      socket.add(first.sublist(0, 2));
      await socket.flush();
      socket.add([...first.sublist(2), ...frame(2)]);
      await socket.flush();
      final parsed = await messages.timeout(const Duration(seconds: 2));
      expect(parsed.map((m) => m.payload['requestId']), [1, 2]);
      expect(parsed.every((m) => m.sourceId == 'receiver-transport'), true);
    },
  );
}
