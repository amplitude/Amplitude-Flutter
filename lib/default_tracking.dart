/// Tracking default events.
///
/// Different platforms have different default events.
/// Refer to platform specific docs for more details.
///
/// * [iOS](https://www.docs.developers.amplitude.com/data/sdks/ios-swift/#tracking-default-events)
/// * [Android](https://www.docs.developers.amplitude.com/data/sdks/android-kotlin/#tracking-default-events)
/// * [Web](https://www.docs.developers.amplitude.com/data/sdks/browser-2/#tracking-default-events)
class DefaultTrackingOptions {
  final bool sessions;

  /// Mobile (iOS and Android) specific
  final bool appLifecycles;
  // TODO(xinyi): implement screenViews in Flutter
  // /// Mobile (iOS and Android) specific
  // final bool screenViews;
  /// Android specific
  final bool deepLinks;

  /// Web specific
  final bool attribution;

  /// Web specific
  final bool pageViews;

  /// Web specific
  final bool formInteractions;

  /// Web specific
  final bool fileDownloads;

  const DefaultTrackingOptions({
    this.sessions = true,
    this.appLifecycles = false,
    // this.screenViews = false,
    this.deepLinks = false,
    this.attribution = true,
    this.pageViews = true,
    this.formInteractions = true,
    this.fileDownloads = true,
  });

  /// Enable all default tracking options.
  ///
  /// Notice that different platforms have different default events.
  factory DefaultTrackingOptions.all() {
    return const DefaultTrackingOptions(
      sessions: true,
      appLifecycles: true,
      // screenViews: true,
      deepLinks: true,
      attribution: true,
      pageViews: true,
      formInteractions: true,
      fileDownloads: true,
    );
  }

  /// Disable all default tracking options.
  factory DefaultTrackingOptions.none() {
    return const DefaultTrackingOptions(
      sessions: false,
      appLifecycles: false,
      // screenViews: false,
      deepLinks: false,
      attribution: false,
      pageViews: false,
      formInteractions: false,
      fileDownloads: false,
    );
  }

  Map<String, bool> toMap() {
    return {
      'sessions': sessions,
      'appLifecycles': appLifecycles,
      'deepLinks': deepLinks,
      'attribution': attribution,
      'pageViews': pageViews,
      'formInteractions': formInteractions,
      'fileDownloads': fileDownloads,
    };
  }
}
