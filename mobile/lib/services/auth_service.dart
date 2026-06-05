import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class AuthService {
  final _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  bool get isLoggedIn => currentSession != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AppConfig.redirectUrl,
    );
  }

  Future<void> signInWithApple() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: AppConfig.redirectUrl,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
