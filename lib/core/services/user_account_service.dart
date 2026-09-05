import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_account.dart';

class UserAccountService {
  UserAccountService._();

  static final instance = UserAccountService._();
  final _supabase = Supabase.instance.client;

  Future<UserAccount?> get(String userId) async {
    final data = await _supabase
        .from('user_account')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return data == null ? null : UserAccount.fromJson(data);
  }

  Future<UserAccount> saveDeliveryAddress({
    required String userId,
    required String receiverName,
    required String addressLine1,
    required String addressLine2,
    required String statePincode,
  }) async {
    final data = await _supabase
        .from('user_account')
        .upsert({
          'id': userId,
          'receiver_name': receiverName.trim(),
          'address_line1': addressLine1.trim(),
          'address_line2': addressLine2.trim().isEmpty
              ? null
              : addressLine2.trim(),
          'state_pincode': statePincode.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'id')
        .select()
        .single();
    return UserAccount.fromJson(data);
  }
}
