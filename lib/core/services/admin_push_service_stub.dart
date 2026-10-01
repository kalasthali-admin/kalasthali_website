class AdminPushService {
  static bool get isSupported => false;
  static String get unavailableReason =>
      'Web Push is unavailable outside a browser build.';
  Future<bool> isEnabled() async => false;
  Future<void> enable() => throw UnsupportedError('Web Push is unavailable.');
  Future<void> disable() => throw UnsupportedError('Web Push is unavailable.');
}
