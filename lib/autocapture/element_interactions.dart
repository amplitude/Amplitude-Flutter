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
      // Serialize as the default options map (not a bare `true`) so the
      // Flutter-aware cssSelectorAllowlist is applied. A bare `true` would keep
      // the Browser SDK's tag-based default, which never matches Flutter's
      // semantic-role nodes, so "enabled" clicks would capture nothing on web.
      ElementInteractionsEnabled() => const ElementInteractionsOptions().toMap(),
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
/// **Flutter web requirement.** DOM-based capture only sees real DOM nodes.
/// With the default CanvasKit renderer the UI is painted to a `<canvas>`, so the
/// Browser SDK can only observe elements from Flutter's accessibility semantics
/// tree, which must be enabled globally (e.g. via
/// `SemanticsBinding.instance.ensureSemantics()`). Enabling semantics app-wide
/// has a runtime cost and known side effects, so it is not recommended unless
/// your app already relies on semantics.
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
  /// Default `cssSelectorAllowlist` used when one is not supplied.
  ///
  /// Flutter web renders interactive widgets into the accessibility semantics
  /// tree as `<flt-semantics>` nodes carrying ARIA roles rather than native HTML
  /// tags, so the Browser SDK's tag-based defaults (`a`, `button`, `input`, …)
  /// never match Flutter UI and nothing is captured. This list mirrors the
  /// common interactive tags and adds the semantic-role selectors Flutter emits
  /// so opting in captures Flutter widgets out of the box. Override
  /// [cssSelectorAllowlist] to tune it (pass `cssSelectorAllowlist: null` to fall
  /// back to the Browser SDK's own default instead).
  static const List<String> defaultCssSelectorAllowlist = [
    // Standard interactive HTML elements (Browser SDK defaults).
    'a',
    'button',
    'input',
    'select',
    'textarea',
    'label',
    // Flutter accessibility-tree roles.
    '[role="button"]',
    '[role="link"]',
    '[role="checkbox"]',
    '[role="radio"]',
    '[role="switch"]',
    '[role="tab"]',
    '[role="menuitem"]',
    '[role="textbox"]',
  ];

  /// Web specific
  ///
  /// List of CSS selectors that gate which elements are tracked. Only elements
  /// matching a selector generate `[Amplitude] Element Clicked` events.
  ///
  /// Defaults to [defaultCssSelectorAllowlist], which includes Flutter semantic
  /// roles so clicks on Flutter widgets are captured on web. Pass an explicit
  /// list to replace it, or `null` to omit the key entirely and use the Browser
  /// SDK's own default allowlist.
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
    this.cssSelectorAllowlist = defaultCssSelectorAllowlist,
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
/// Enables click tracking with the Flutter-aware
/// [ElementInteractionsOptions.defaultCssSelectorAllowlist], so clicks on
/// Flutter web widgets are captured. Use [ElementInteractionsOptions] if you need
/// to customize the allowlist or the other options.
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
