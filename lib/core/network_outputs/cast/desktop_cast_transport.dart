import 'dart:convert';

// The pinned package's framing channel is isolated here: its high-level session
// would introduce a second media server and bypass our authorized file leases.
// ignore: implementation_imports
import 'package:dart_cast/src/protocols/chromecast/castv2_channel.dart';

class DesktopCastMessage {
  const DesktopCastMessage(this.namespace, this.sourceId, this.payload);
  final String namespace;
  final String sourceId;
  final Map<String, dynamic> payload;
}

abstract interface class DesktopCastTransport {
  Future<void> connect(String host, int port);
  Stream<DesktopCastMessage> get messages;
  void send(String namespace, String destination, Map<String, dynamic> payload);
  Future<void> close();
}

class CastV2DesktopTransport implements DesktopCastTransport {
  final _channel = CastV2Channel();

  @override
  Future<void> connect(String host, int port) =>
      _channel.connect(host, port: port);

  @override
  Stream<DesktopCastMessage> get messages => _channel.messageStream.map((msg) {
    final payload = jsonDecode(msg.payloadUtf8);
    return DesktopCastMessage(
      msg.namespace_,
      msg.sourceId,
      Map<String, dynamic>.from(payload as Map),
    );
  });

  @override
  void send(
    String namespace,
    String destination,
    Map<String, dynamic> payload,
  ) {
    _channel.sendMessage(
      namespace: namespace,
      sourceId: 'ppplayer-sender',
      destinationId: destination,
      payload: jsonEncode(payload),
    );
  }

  @override
  Future<void> close() => _channel.close();
}
