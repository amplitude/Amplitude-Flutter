import 'amplitude_mobile_stub.dart'
    if (dart.library.html) 'amplitude_web.dart'
    if (dart.library.io) 'amplitude_mobile_stub.dart';


class Amplitude {
  Amplitude._();

  final AmplitudeWeb _amplitudeWeb = AmplitudeWeb();

  static Amplitude getInstance({String instanceName = '\$default_instance'}) =>
      Amplitude._();

  void init(
    String apiKey,
    String? optUserId,
    Map<String, dynamic>? optConfig,
  ) =>
      _amplitudeWeb.init(
        apiKey,
        // optUserId: optUserId,
        // optConfig: optConfig,
      );

  void logEvent(
    String name,
    Map<String, String>? params,
  ) =>
      _amplitudeWeb.logEvent(
        name,
        //params: params,
      );

  void setOptOut(bool enable) => _amplitudeWeb.setOptOut(enable);

  void setUserProperties(Map<String, String> properties) =>
      _amplitudeWeb.setUserProperties(properties);

  setGroup(String text, String text2) {}
}
