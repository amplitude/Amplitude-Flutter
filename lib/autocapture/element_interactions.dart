/// AutoCapture ElementInteractions (click tracking) configuration.
///
/// Disable or enable ElementInteractions by using class extensions
/// [ElementInteractionsDisabled]/[ElementInteractionsEnabled], or use
/// [ElementInteractionsOptions] for more granular control.
sealed class ElementInteractions {
  const ElementInteractions();

  static dynamic toMapOrBool(ElementInteractions elementInteractions) {
    return switch (elementInteractions) {
      ElementInteractionsOptions() => elementInteractions.toMap(),
      ElementInteractionsEnabled() => true,
      ElementInteractionsDisabled() => false,
      Type() => throw UnimplementedError(),
    };
  }
}

/// Options for the autocapture elementInteractions feature.
///
/// Element interactions (click tracking) are only supported on Web, through the
/// Browser SDK. Requires Browser SDK >= 2.10.0.
/// Refer to [docs](https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#autocapture) for more details.
///
/// Example usage:
///
///```dart
/// var analytics = Amplitude(
///     Configuration(
///         apiKey: 'your_api_key',
///         autocapture: AutocaptureOptions(
///             elementInteractions: ElementInteractionsOptions(
///               cssSelectorAllowlist: ['a', 'button', 'input'],
///               actionClickAllowlist: ['div'],
///               dataAttributePrefix: 'data-amp-track-',
///             ),
///         ),
///     )
/// );
/// ```
class ElementInteractionsOptions extends ElementInteractions {
  /// Web specific
  ///
  /// List of CSS selectors that gate which elements are tracked. When set, only
  /// elements matching a selector generate `[Amplitude] Element Clicked` events.
  final List<String>? cssSelectorAllowlist;

  /// Web specific
  ///
  /// List of CSS selectors whose clicks should also be attributed to a matching
  /// ancestor element (useful when clicks land on a child of the tracked element).
  final List<String>? actionClickAllowlist;

  /// Web specific
  ///
  /// Prefix for `data-*` attributes that are captured as event properties.
  final String? dataAttributePrefix;

  /// Web specific
  ///
  /// List of page URLs on which element interactions are tracked.
  ///
  /// Note: only [String] entries are supported from Flutter. The Browser SDK
  /// also accepts JavaScript `RegExp` entries, but those cannot be serialized
  /// across the platform channel.
  final List<String>? pageUrlAllowlist;

  /// Web specific
  ///
  /// Configuration for autocapturing element interaction (click) events.
  ///
  /// See [docs](https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#autocapture) for more information.
  const ElementInteractionsOptions({
    this.cssSelectorAllowlist,
    this.actionClickAllowlist,
    this.dataAttributePrefix,
    this.pageUrlAllowlist,
  });

  Map<String, dynamic> toMap() {
    var elementInteractionsOptions = <String, dynamic>{};
    if (cssSelectorAllowlist != null) {
      elementInteractionsOptions['cssSelectorAllowlist'] = cssSelectorAllowlist;
    }
    if (actionClickAllowlist != null) {
      elementInteractionsOptions['actionClickAllowlist'] = actionClickAllowlist;
    }
    if (dataAttributePrefix != null) {
      elementInteractionsOptions['dataAttributePrefix'] = dataAttributePrefix;
    }
    if (pageUrlAllowlist != null) {
      elementInteractionsOptions['pageUrlAllowlist'] = pageUrlAllowlist;
    }
    return elementInteractionsOptions;
  }
}

/// Disable autocapture ElementInteractions.
///
/// Example usage:
///
///```dart
/// var analytics = Amplitude(
///     Configuration(
///         apiKey: 'your_api_key',
///         autocapture: AutocaptureOptions(
///             elementInteractions: ElementInteractionsDisabled(),
///         ),
///     )
/// );
/// ```
class ElementInteractionsDisabled extends ElementInteractions {
  const ElementInteractionsDisabled();
}

/// Enable autocapture ElementInteractions.
///
/// Example usage:
///
///```dart
/// var analytics = Amplitude(
///     Configuration(
///         apiKey: 'your_api_key',
///         autocapture: AutocaptureOptions(
///             elementInteractions: ElementInteractionsEnabled(),
///         ),
///     )
/// );
/// ```
class ElementInteractionsEnabled extends ElementInteractions {
  const ElementInteractionsEnabled();
}
