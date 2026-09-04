import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();

  static final _auth = Supabase.instance.client.auth;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get userChanges =>
      _auth.onAuthStateChange.map((state) => state.session?.user);

  static String firstName(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final suppliedName =
        metadata['first_name'] ?? metadata['firstName'] ?? metadata['name'];
    if (suppliedName is String && suppliedName.trim().isNotEmpty) {
      return suppliedName.trim().split(RegExp(r'\s+')).first;
    }
    return (user.email ?? 'Account').split('@').first;
  }
}
