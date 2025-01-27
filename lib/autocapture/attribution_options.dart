class AttributionOptions {
  /// Web specific
  ///
  /// List of referrers to exclude from attribution tracking.
  ///
  /// Sets rules to decide which referrers to exclude from tracking as traffic source.
  /// See [docs](https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#track-marketing-attribution) for more information.
  final List<String>? excludeReferrers;
  /// Web specific
  ///
  /// Sets the value to represent undefined/no initial campaign parameter for first-touch attribution. The default value is "EMPTY".
  final String? initialEmptyValue;
  /// Web specific
  ///
  /// Configures Amplitude to start a new session if any campaign parameter changes. The default value is false.
  final bool resetSessionOnNewCampaign;

  /// Web specific
  ///
  /// Attribution options for the autocapture feature.
  ///
  /// See [docs](https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#track-marketing-attribution) for more information.
  const AttributionOptions({
    this.excludeReferrers,
    this.initialEmptyValue = 'EMPTY',
    this.resetSessionOnNewCampaign = false,
  });

  Map<String, dynamic> toMap() {
    var attributionOptions = {
      'initialEmptyValue': initialEmptyValue,
      'resetSessionOnNewCampaign': resetSessionOnNewCampaign,
    };
    if (excludeReferrers != null) {
      attributionOptions['excludeReferrers'] = excludeReferrers;
    }
    return attributionOptions;
  }
}
