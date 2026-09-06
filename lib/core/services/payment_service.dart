import '../models/payment_result.dart';
import 'payment_service_stub.dart'
    if (dart.library.html) 'payment_service_web.dart'
    as platform;

class PaymentService {
  PaymentService._();

  static Future<PaymentResult> pay({
    required int amountPaise,
    required String receipt,
    required String description,
    String? customerName,
    String? customerEmail,
    String? customerContact,
    Map<String, Object?> notes = const {},
  }) {
    if (amountPaise < 100) {
      throw ArgumentError('Amount must be at least 100 paise.');
    }
    return platform.pay(
      amountPaise: amountPaise,
      receipt: receipt,
      description: description,
      customerName: customerName,
      customerEmail: customerEmail,
      customerContact: customerContact,
      notes: notes,
    );
  }
}
