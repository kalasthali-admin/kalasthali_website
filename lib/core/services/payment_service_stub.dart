import '../models/payment_result.dart';

Future<PaymentResult> pay({
  required int amountPaise,
  required String receipt,
  required String description,
  String? customerName,
  String? customerEmail,
  String? customerContact,
  Map<String, Object?> notes = const {},
}) {
  throw UnsupportedError('Razorpay Checkout is available on web builds only.');
}
