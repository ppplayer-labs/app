import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

import 'dlna_device.dart';

class DlnaActionException implements Exception {
  const DlnaActionException(this.action, this.code, this.description);
  final String action;
  final int? code;
  final String description;
  bool get unsupported => code == 401 || code == 602 || code == 710;
  @override
  String toString() =>
      'DLNA $action failed${code == null ? '' : ' ($code)'}: $description';
}

/// Per-exchange clients let a deadline actually close its socket. Responses are
/// bounded before parsing; remote XML never controls a subsequent HTTP target.
class DlnaSoapClient {
  DlnaSoapClient({
    this.timeout = const Duration(seconds: 8),
    this.maximumXmlBytes = 512 * 1024,
  });
  final Duration timeout;
  final int maximumXmlBytes;
  final _clients = <HttpClient>{};
  bool _disposed = false;

  Future<String> getXml(Uri uri) => _exchange(uri, 'GET');

  Future<String> _exchange(
    Uri uri,
    String method, {
    String? body,
    String? action,
  }) async {
    if (_disposed) throw StateError('DLNA transport is disposed');
    if (!{'http', 'https'}.contains(uri.scheme) || uri.userInfo.isNotEmpty)
      throw const FormatException('Invalid UPnP endpoint');
    final client = HttpClient()..connectionTimeout = timeout;
    _clients.add(client);
    try {
      return await () async {
        final request = await client.openUrl(method, uri);
        request.followRedirects = false;
        if (body != null) {
          request.headers.set(
            HttpHeaders.contentTypeHeader,
            'text/xml; charset="utf-8"',
          );
          request.headers.set('SOAPACTION', '"$action"');
          final bytes = utf8.encode(body);
          request.contentLength = bytes.length;
          request.add(bytes);
        }
        final response = await request.close();
        final bytes = <int>[];
        await for (final chunk in response) {
          if (bytes.length + chunk.length > maximumXmlBytes)
            throw const FormatException('UPnP response exceeds limit');
          bytes.addAll(chunk);
        }
        final text = utf8.decode(bytes);
        if (method == 'GET' && response.statusCode != 200)
          throw HttpException(
            'UPnP description returned HTTP ${response.statusCode}',
          );
        // Fault bodies under HTTP 500 and even HTTP 200 are parsed by invoke.
        if (method == 'POST' &&
            response.statusCode != 200 &&
            response.statusCode != 500) {
          throw HttpException(
            'UPnP action returned HTTP ${response.statusCode}',
          );
        }
        return text;
      }().timeout(timeout);
    } finally {
      _clients.remove(client);
      client.close(force: true);
    }
  }

  Future<Map<String, String>> invoke(
    DlnaService service,
    String action,
    Map<String, Object> arguments,
  ) async {
    final builder = XmlBuilder();
    builder.element(
      's:Envelope',
      attributes: {
        'xmlns:s': 'http://schemas.xmlsoap.org/soap/envelope/',
        's:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/',
      },
      nest: () {
        builder.element(
          's:Body',
          nest: () {
            builder.element(
              'u:$action',
              attributes: {'xmlns:u': service.type},
              nest: () {
                for (final argument in arguments.entries) {
                  builder.element(
                    argument.key,
                    nest: argument.value.toString(),
                  );
                }
              },
            );
          },
        );
      },
    );
    final xml = await _exchange(
      service.controlUri,
      'POST',
      body: builder.buildDocument().toXmlString(),
      action: '${service.type}#$action',
    );
    final document = XmlDocument.parse(xml);
    final elements = document.descendants.whereType<XmlElement>();
    final fault = elements.where((e) => e.name.local == 'Fault').firstOrNull;
    if (fault != null) {
      final code = fault.descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local == 'errorCode')
          .firstOrNull
          ?.innerText;
      final description = fault.descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local == 'errorDescription')
          .firstOrNull
          ?.innerText;
      throw DlnaActionException(
        action,
        int.tryParse(code ?? ''),
        description ?? 'Renderer rejected the action',
      );
    }
    final reply = elements
        .where((e) => e.name.local == '${action}Response')
        .firstOrNull;
    if (reply == null)
      throw DlnaActionException(action, null, 'Invalid renderer response');
    return {
      for (final argument in reply.childElements)
        argument.name.local: argument.innerText,
    };
  }

  Future<void> inspect(DlnaDevice device) async {
    for (final service in device.services.values) {
      service.applyDescription(await getXml(service.descriptionUri));
    }
    final connection = device.connection;
    if (connection?.supports('GetProtocolInfo') == true) {
      final info = await invoke(connection!, 'GetProtocolInfo', const {});
      device.sinkProtocolInfos = (info['Sink'] ?? '')
          .split(',')
          .where((entry) => entry.split(':').length >= 4)
          .toList();
    }
  }

  void cancelPending() {
    for (final client in _clients.toList()) {
      client.close(force: true);
    }
  }

  void dispose() {
    _disposed = true;
    cancelPending();
  }
}
