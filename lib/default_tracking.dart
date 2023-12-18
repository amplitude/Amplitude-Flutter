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
  final MobileDefaultTrackingOptions mobileDefaultTrackingOptions;
  final AndroidDefaultTrackingOptions androidDefaultTrackingOptions;
  final WebDefaultTrackingOptions webDefaultTrackingOptions;

  const DefaultTrackingOptions({
    this.sessions = true, 
    this.mobileDefaultTrackingOptions = const MobileDefaultTrackingOptions(),
    this.androidDefaultTrackingOptions = const AndroidDefaultTrackingOptions(),
    this.webDefaultTrackingOptions = const WebDefaultTrackingOptions(),
  });

  /// Enable all default tracking options.
  /// 
  /// Notice that different platforms have different default events.
  factory DefaultTrackingOptions.all() {
    return const DefaultTrackingOptions(
      sessions: true, 
      mobileDefaultTrackingOptions: MobileDefaultTrackingOptions(
        appLifecycles: true, 
        screenViews: true,
      ),
      androidDefaultTrackingOptions: AndroidDefaultTrackingOptions(
        deepLinks: true,
      ),
      webDefaultTrackingOptions: WebDefaultTrackingOptions(
        attribution: true,
        pageViews: true,
        formInteractions: true,
        fileDownloads: true,
      ),
    );
  }

  /// Disable all default tracking options.
  factory DefaultTrackingOptions.none() {
    return const DefaultTrackingOptions(
      sessions: false, 
      mobileDefaultTrackingOptions: MobileDefaultTrackingOptions(
        appLifecycles: false, 
        screenViews: false,
      ),
      androidDefaultTrackingOptions: AndroidDefaultTrackingOptions(
        deepLinks: false,
      ),
      webDefaultTrackingOptions: WebDefaultTrackingOptions(
        attribution: false,
        pageViews: false,
        formInteractions: false,
        fileDownloads: false,
      ),
    );
  }

  Map<String, bool> toMap() {
    return {
      'sessions': sessions,
      ...mobileDefaultTrackingOptions.toMap(),
      ...androidDefaultTrackingOptions.toMap(),
      ...webDefaultTrackingOptions.toMap(),
    };
  }
}

class MobileDefaultTrackingOptions{
  final bool appLifecycles;
  final bool screenViews;

  const MobileDefaultTrackingOptions({
    this.appLifecycles = false, 
    this.screenViews = false,
  });

  Map<String, bool> toMap() {
    return {
      'appLifecycles': appLifecycles,
      'screenViews': screenViews,
    };
  }
}

class AndroidDefaultTrackingOptions{
  final bool deepLinks;

  const AndroidDefaultTrackingOptions({
    this.deepLinks = false,
  });

  Map<String, bool> toMap() {
    return {
      'deepLinks': deepLinks,
    };
  }
}

class WebDefaultTrackingOptions{
  final bool attribution;
  final bool pageViews;
  final bool formInteractions;
  final bool fileDownloads;

  const WebDefaultTrackingOptions({
    this.attribution = true,
    this.pageViews = true,
    this.formInteractions = true,
    this.fileDownloads = true,
  });

  Map<String, bool> toMap() {
    return {
      'attribution': attribution,
      'pageViews': pageViews,
      'formInteractions': formInteractions,
      'fileDownloads': fileDownloads,
    };
  }
}