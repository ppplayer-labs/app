import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Socket.connect address semantics', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final socket = await Socket.connect(
      InternetAddress.loopbackIPv4,
      server.port,
    );

    expect(socket.remoteAddress.address, InternetAddress.loopbackIPv4.address);
    expect(socket.address.address, InternetAddress.loopbackIPv4.address);

    socket.destroy();
    await server.close();
  });
}
