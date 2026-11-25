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
  static bool get isSupported => unavailableReason.isEmpty;
  static String get unavailableReason {
    if (_vapidPublicKey.isEmpty) {
      return 'VAPID_PUBLIC_KEY was not included in this Vercel build.';
    }
    if (!_supported().toDart) {
      return 'This browser does not support the required Web Push APIs.';
    }
    return '';
  }

  Future<bool> isEnabled() async => (await _enabled().toDart).toDart;

  Future<void> enable() async {
    final subscription = jsonDecode(
      (await _enable(_vapidPublicKey.toJS).toDart).toDart,
    );
    try {
      await Supabase.instance.client.functions.invoke(
        'register-admin-push-subscription',
        body: {'subscription': subscription},
      );
    } on FunctionException catch (error) {
      await _disable().toDart;
      throw Exception(
        _functionError(error, 'Could not register order notifications.'),
      );
    } catch (_) {
      await _disable().toDart;
      throw Exception(
        'Could not contact the notification service. Please try again.',
      );
    }
  }

  Future<void> disable() async {
    final endpoint = (await _disable().toDart).toDart;
    if (endpoint.isEmpty) return;
    try {
      await Supabase.instance.client.functions.invoke(
        'unregister-admin-push-subscription',
        body: {'endpoint': endpoint},
      );
    } on FunctionException catch (error) {
      throw Exception(
        _functionError(error, 'Could not disable order notifications.'),
      );
    } catch (_) {
      throw Exception(
        'Could not contact the notification service. Please try again.',
      );
    }
  }

  String _functionError(FunctionException error, String fallback) {
    final details = error.details;
    if (details is Map && details['error'] != null) {
      return details['error'].toString();
    }
    return error.reasonPhrase?.trim().isNotEmpty == true
        ? error.reasonPhrase!.trim()
        : fallback;
  }
}
