class AdminPushService {
  static bool get isSupported => false;
  Future<bool> isEnabled() async => false;
  Future<void> enable() => throw UnsupportedError('Web Push is unavailable.');
  Future<void> disable() => throw UnsupportedError('Web Push is unavailable.');
}
