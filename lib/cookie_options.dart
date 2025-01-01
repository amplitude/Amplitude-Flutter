/// Cookie options for Web SDK
///
/// Refer to the official documentation for Web more details:
/// https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#configure-the-sdk
class CookieOptions {
  final String domain;
  final int expiration;
  final String sameSite;
  final bool secure;
  final bool upgrade;

  CookieOptions({
    this.domain = '',
    this.expiration = 365,
    this.sameSite = 'Lax',
    this.secure = false,
    this.upgrade = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'domain': domain,
      'expiration': expiration,
      'sameSite': sameSite,
      'secure': secure,
      'upgrade': upgrade,
    };
  }
}
