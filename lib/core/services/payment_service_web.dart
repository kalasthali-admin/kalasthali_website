import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/payment_result.dart';

@JS('KalasthaliPayments')
external JSObject? get _payments;

Future<PaymentResult> pay({
  required int amountPaise,
  required String receipt,
  required String description,
  String? customerName,
  String? customerEmail,
  String? customerContact,
  Map<String, Object?> notes = const {},
}) async {
  final session = Supabase.instance.client.auth.currentSession;
  final accessToken = session?.accessToken;
  if (accessToken == null || accessToken.isEmpty) {
    throw StateError('Log in before continuing to payment.');
  }

  final payments = _payments;
  if (payments == null) {
    throw StateError('Payment checkout is not available yet.');
  }

  final payload = {
    'amount': amountPaise,
    'currency': 'INR',
    'receipt': receipt,
    'description': description,
    'customerName': customerName,
    'customerEmail': customerEmail,
    'customerContact': customerContact,
    'accessToken': accessToken,
    'notes': notes,
  }.jsify();
  final promise = payments.callMethodVarArgs<JSPromise<JSAny?>>(
    'payWithRazorpay'.toJS,
    [payload],
  );
  final response = await promise.toDart;
  if (response == null || !response.isA<JSObject>()) {
    throw StateError('Payment verification returned an invalid response.');
  }
  final responseObject = response as JSObject;
  final paymentId = responseObject
      .getProperty<JSString?>('payment_id'.toJS)
      ?.toDart;
  final orderId = responseObject
      .getProperty<JSString?>('order_id'.toJS)
      ?.toDart;
  if (paymentId == null || orderId == null) {
    throw StateError('Payment verification returned an invalid response.');
  }
  return PaymentResult(paymentId: paymentId, orderId: orderId);
}
