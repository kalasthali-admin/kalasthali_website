import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();

  static const _adminEmails = {
    'admin.kalasthali@gmail.com',
    'nisharohilla651@gmail.com',
    'rehaan.tamboli26@gmail.com'
  };

  static final _auth = Supabase.instance.client.auth;

  static User? get currentUser => _auth.currentUser;
  static Session? get currentSession => _auth.currentSession;
  static Stream<User?> get userChanges =>
      _auth.onAuthStateChange.map((state) => state.session?.user);

  static bool isAdmin(User? user) =>
      user?.email != null && _adminEmails.contains(user!.email!.toLowerCase());

  static Future<bool> signInWithGoogle() => _auth.signInWithOAuth(
    OAuthProvider.google,
    redirectTo: kIsWeb ? '${Uri.base.origin}/account' : null,
  );

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
