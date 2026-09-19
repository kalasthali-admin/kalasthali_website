import 'dart:convert';
import 'dart:js_interop';

import 'package:supabase_flutter/supabase_flutter.dart';

@JS('kalasthaliPushSupported')
external JSBoolean _supported();
@JS('kalasthaliPushEnabled')
external JSPromise<JSBoolean> _enabled();
@JS('kalasthaliPushEnable')
external JSPromise<JSString> _enable(JSString vapidKey);
@JS('kalasthaliPushDisable')
external JSPromise<JSString> _disable();

class AdminPushService {
  static const _vapidPublicKey = String.fromEnvironment('VAPID_PUBLIC_KEY');
  static bool get isSupported =>
      _vapidPublicKey.isNotEmpty && _supported().toDart;

  Future<bool> isEnabled() async => (await _enabled().toDart).toDart;

  Future<void> enable() async {
    final subscription = jsonDecode(
      (await _enable(_vapidPublicKey.toJS).toDart).toDart,
    );
    await Supabase.instance.client.functions.invoke(
      'register-admin-push-subscription',
      body: {'subscription': subscription},
    );
  }

  Future<void> disable() async {
    final endpoint = (await _disable().toDart).toDart;
    if (endpoint.isEmpty) return;
    await Supabase.instance.client.functions.invoke(
      'unregister-admin-push-subscription',
      body: {'endpoint': endpoint},
    );
  }
}
