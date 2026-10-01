import 'package:xml/xml.dart';

import '../models.dart';

XmlElement? dlnaChild(XmlElement element, String name) {
  for (final child in element.childElements) {
    if (child.name.local == name) return child;
  }
  return null;
}

String? dlnaText(XmlElement element, String name) =>
    dlnaChild(element, name)?.innerText.trim();

class DlnaService {
  DlnaService({
    required this.type,
    required this.controlUri,
    required this.descriptionUri,
    this.eventUri,
    this.actions = const {},
    this.seekModes = const {},
    this.volumeMinimum = 0,
    this.volumeMaximum = 100,
    this.volumeStep = 1,
  });
  final String type;
  final Uri controlUri;
  final Uri descriptionUri;
  final Uri? eventUri;
  Set<String> actions;
  Set<String> seekModes;
  int volumeMinimum;
  int volumeMaximum;
  int volumeStep;

  String get name => type.split(':').reversed.skip(1).first;
  bool supports(String action) => actions.contains(action);
  void applyDescription(String xml) {
    final document = XmlDocument.parse(xml);
    actions = document.descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == 'action')
        .map((e) => dlnaText(e, 'name'))
        .whereType<String>()
        .toSet();
    for (final variable in document.descendants.whereType<XmlElement>().where(
      (e) => e.name.local == 'stateVariable',
    )) {
      if (dlnaText(variable, 'name') == 'A_ARG_TYPE_SeekMode') {
        seekModes = variable.descendants
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'allowedValue')
            .map((e) => e.innerText.trim())
            .toSet();
      }
      if (dlnaText(variable, 'name') == 'Volume') {
        final range = dlnaChild(variable, 'allowedValueRange');
        if (range != null) {
          volumeMinimum = int.tryParse(dlnaText(range, 'minimum') ?? '') ?? 0;
          volumeMaximum = int.tryParse(dlnaText(range, 'maximum') ?? '') ?? 100;
          volumeStep = int.tryParse(dlnaText(range, 'step') ?? '') ?? 1;
          if (volumeMaximum <= volumeMinimum || volumeStep < 1) {
            volumeMinimum = 0;
            volumeMaximum = 100;
            volumeStep = 1;
          }
        }
      }
    }
  }
}

class DlnaDevice {
  DlnaDevice({
    required this.id,
    required this.name,
    required this.descriptionUri,
    required this.services,
    this.manufacturer,
    this.model,
    this.sinkProtocolInfos = const [],
    DateTime? expires,
  }) : expires = expires ?? DateTime.now().add(const Duration(minutes: 3));
  final String id;
  final String name;
  final Uri descriptionUri;
  final Map<String, DlnaService> services;
  final String? manufacturer;
  final String? model;
  List<String> sinkProtocolInfos;
  DateTime expires;

  DlnaService? get transport => services['AVTransport'];
  DlnaService? get rendering => services['RenderingControl'];
  DlnaService? get connection => services['ConnectionManager'];

  OutputCapabilities get capabilities {
    final mime = sinkProtocolInfos
        .map((entry) => entry.split(':'))
        .where((parts) => parts.length >= 4 && parts.first == 'http-get')
        .map((parts) => parts[2])
        .toSet();
    final any = mime.contains('*') || mime.contains('*/*');
    return OutputCapabilities(
      audio:
          any ||
          mime.any(
            (entry) => entry.startsWith('audio/') || entry.contains('mpegurl'),
          ),
      video:
          any ||
          mime.any(
            (entry) => entry.startsWith('video/') || entry.contains('mpegurl'),
          ),
      play: transport?.supports('Play') == true,
      pause: transport?.supports('Pause') == true,
      stop: transport?.supports('Stop') == true,
      seek:
          transport?.supports('Seek') == true &&
          transport!.seekModes.contains('REL_TIME'),
      volume:
          rendering?.supports('GetVolume') == true &&
          rendering!.supports('SetVolume'),
      mute:
          rendering?.supports('GetMute') == true &&
          rendering!.supports('SetMute'),
      live: mime.isNotEmpty,
      mimeTypes: mime,
      sinkProtocolInfos: sinkProtocolInfos
          .where((e) => e.startsWith('http-get:'))
          .toList(),
    );
  }

  PlaybackOutput get output => PlaybackOutput(
    id: id,
    name: name,
    kind: OutputKind.dlna,
    endpointUri: descriptionUri,
    manufacturer: manufacturer,
    model: model,
    capabilities: capabilities,
    metadata: {
      'avTransport': transport != null,
      'renderingControl': rendering != null,
      'connectionManager': connection != null,
      'ipv6': false,
    },
  );

  static List<DlnaDevice> fromDescription(
    String xml,
    Uri location, {
    DateTime? expires,
  }) {
    final document = XmlDocument.parse(xml);
    final baseText = dlnaText(document.rootElement, 'URLBase');
    final base = baseText == null ? location : location.resolve(baseText);
    if (!{'http', 'https'}.contains(base.scheme) ||
        base.host != location.host) {
      throw const FormatException(
        'Device URLBase must remain on the discovered host',
      );
    }
    final devices = <DlnaDevice>[];
    for (final element in document.descendants.whereType<XmlElement>().where(
      (e) => e.name.local == 'device',
    )) {
      final type = dlnaText(element, 'deviceType') ?? '';
      if (!RegExp(
        r'^urn:schemas-upnp-org:device:MediaRenderer:\d+$',
      ).hasMatch(type))
        continue;
      final services = <String, DlnaService>{};
      final list = dlnaChild(element, 'serviceList');
      for (final service in list?.childElements ?? <XmlElement>[]) {
        final urn = dlnaText(service, 'serviceType') ?? '';
        final match = RegExp(
          r'^urn:schemas-upnp-org:service:(AVTransport|RenderingControl|ConnectionManager):\d+$',
        ).firstMatch(urn);
        final control = dlnaText(service, 'controlURL');
        final scpd = dlnaText(service, 'SCPDURL');
        if (match == null || control == null || scpd == null) continue;
        Uri safe(String value) {
          final resolved = base.resolve(value);
          if (!{'http', 'https'}.contains(resolved.scheme) ||
              resolved.host != location.host ||
              resolved.userInfo.isNotEmpty) {
            throw const FormatException(
              'Service must remain on the discovered host',
            );
          }
          return resolved;
        }

        final event = dlnaText(service, 'eventSubURL');
        services[match.group(1)!] = DlnaService(
          type: urn,
          controlUri: safe(control),
          descriptionUri: safe(scpd),
          eventUri: event == null ? null : safe(event),
        );
      }
      if (!services.containsKey('AVTransport')) continue;
      devices.add(
        DlnaDevice(
          id: dlnaText(element, 'UDN') ?? location.toString(),
          name: dlnaText(element, 'friendlyName') ?? 'DLNA renderer',
          manufacturer: dlnaText(element, 'manufacturer'),
          model: dlnaText(element, 'modelName'),
          descriptionUri: location,
          services: services,
          expires: expires,
        ),
      );
    }
    return devices;
  }
}
