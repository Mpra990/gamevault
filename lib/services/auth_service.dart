import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Realiza o login com email e senha
  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Realiza o cadastro de novo utilizador (conforme sua tela)
  Future<AuthResponse> signUp(String email, String password) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  // Realiza o logout
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Obtém o usuário atual logado
  User? get currentUser => _supabase.auth.currentUser;
}
