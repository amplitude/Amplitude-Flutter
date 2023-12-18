/// Tracking default events.
/// 
/// Different platforms have different default events. 
/// Refer to platform specific docs for more details.
/// 
/// * [iOS](https://www.docs.developers.amplitude.com/data/sdks/ios-swift/#tracking-default-events)
/// * [Android](https://www.docs.developers.amplitude.com/data/sdks/android-kotlin/#tracking-default-events)
/// * [Web](https://www.docs.developers.amplitude.com/data/sdks/browser-2/#tracking-default-events)

class DefaultTrackingOptions {
  // Available on all platforms: iOS, Android, and Web
  final bool sessions;
  // Available on iOS and Android
  final bool appLifecycles;
  final bool screenViews;
  // Available on Android
  final bool deepLinks;
  // Available on Web
  final bool attribution;
  final bool pageViews;
  final bool formInteractions;
  final bool fileDownloads;

  const DefaultTrackingOptions({
    this.sessions = true, 
    this.appLifecycles = false, 
    this.screenViews = false,
    this.deepLins = false,
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
      screenViews: true,
      deepLins: true,
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
      screenViews: false,
      deepLins: false,
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
      'screenViews': screenViews,
      'deepLins': deepLins,
      'attribution': attribution,
      'pageViews': pageViews,
      'formInteractions': formInteractions,
      'fileDownloads': fileDownloads,
    };
  }
}
