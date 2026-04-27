import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supabase_models.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient _client;

  SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  Future<void> initialize() async {
    final url = dotenv.get('SUPABASE_URL');
    final anonKey = dotenv.get('SUPABASE_ANON_KEY');

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );

    _client = Supabase.instance.client;
  }

  SupabaseClient get client => _client;

  // ============================================================
  // USUARIOS
  // ============================================================
  Future<AppUser?> getUserById(String id) async {
    try {
      final response = await _client
          .from('usuarios')
          .select()
          .eq('id', id)
          .single();
      return AppUser.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<AppUser> createUser(String email, String senhaHash, {String? username, String? avatarUrl}) async {
    final response = await _client
        .from('usuarios')
        .insert({
          'email': email,
          'senha_hash': senhaHash,
          'username': username,
          'avatar_url': avatarUrl,
        })
        .select()
        .single();
    return AppUser.fromJson(response);
  }

  Future<void> updateUser(String id, {String? username, String? avatarUrl}) async {
    await _client.from('usuarios').update({
      'username': username,
      'avatar_url': avatarUrl,
      'atualizado_em': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // ============================================================
  // STATUS JOGO
  // ============================================================
  Future<List<StatusJogo>> getUserGameStatus(String usuarioId) async {
    final response = await _client
        .from('status_jogo')
        .select()
        .eq('usuario_id', usuarioId);
    return (response as List).map((e) => StatusJogo.fromJson(e)).toList();
  }

  Future<StatusJogo?> getGameStatus(String usuarioId, int rawgGameId) async {
    try {
      final response = await _client
          .from('status_jogo')
          .select()
          .eq('usuario_id', usuarioId)
          .eq('rawg_game_id', rawgGameId)
          .single();
      return StatusJogo.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<StatusJogo> updateGameStatus(
    String usuarioId,
    int rawgGameId,
    StatusJogoEnum status, {
    String? rawgSlug,
  }) async {
    try {
      // Tenta atualizar se já existe
      final response = await _client
          .from('status_jogo')
          .update({
            'status': status.value,
            'rawg_slug': rawgSlug,
            'atualizado_em': DateTime.now().toIso8601String(),
          })
          .eq('usuario_id', usuarioId)
          .eq('rawg_game_id', rawgGameId)
          .select()
          .single();
      return StatusJogo.fromJson(response);
    } catch (e) {
      // Se não existe, cria
      final response = await _client
          .from('status_jogo')
          .insert({
            'usuario_id': usuarioId,
            'rawg_game_id': rawgGameId,
            'rawg_slug': rawgSlug,
            'status': status.value,
          })
          .select()
          .single();
      return StatusJogo.fromJson(response);
    }
  }

  Future<void> deleteGameStatus(String usuarioId, int rawgGameId) async {
    await _client
        .from('status_jogo')
        .delete()
        .eq('usuario_id', usuarioId)
        .eq('rawg_game_id', rawgGameId);
  }

  Future<List<StatusJogo>> getGamesByStatus(String usuarioId, StatusJogoEnum status) async {
    final response = await _client
        .from('status_jogo')
        .select()
        .eq('usuario_id', usuarioId)
        .eq('status', status.value);
    return (response as List).map((e) => StatusJogo.fromJson(e)).toList();
  }

  // ============================================================
  // WISHLIST
  // ============================================================
  Future<List<Wishlist>> getUserWishlist(String usuarioId) async {
    final response = await _client
        .from('wishlist')
        .select()
        .eq('usuario_id', usuarioId)
        .order('adicionado_em', ascending: false);
    return (response as List).map((e) => Wishlist.fromJson(e)).toList();
  }

  Future<bool> isGameInWishlist(String usuarioId, int rawgGameId) async {
    try {
      await _client
          .from('wishlist')
          .select()
          .eq('usuario_id', usuarioId)
          .eq('rawg_game_id', rawgGameId)
          .single();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Wishlist> addToWishlist(String usuarioId, int rawgGameId, {String? rawgSlug}) async {
    final response = await _client
        .from('wishlist')
        .insert({
          'usuario_id': usuarioId,
          'rawg_game_id': rawgGameId,
          'rawg_slug': rawgSlug,
        })
        .select()
        .single();
    return Wishlist.fromJson(response);
  }

  Future<void> removeFromWishlist(String usuarioId, int rawgGameId) async {
    await _client
        .from('wishlist')
        .delete()
        .eq('usuario_id', usuarioId)
        .eq('rawg_game_id', rawgGameId);
  }

  // ============================================================
  // AVALIACOES
  // ============================================================
  Future<List<Avaliacao>> getUserAvaliacoes(String usuarioId) async {
    final response = await _client
        .from('avaliacoes')
        .select()
        .eq('usuario_id', usuarioId)
        .order('criado_em', ascending: false);
    return (response as List).map((e) => Avaliacao.fromJson(e)).toList();
  }

  Future<Avaliacao?> getGameAvaliacao(String usuarioId, int rawgGameId) async {
    try {
      final response = await _client
          .from('avaliacoes')
          .select()
          .eq('usuario_id', usuarioId)
          .eq('rawg_game_id', rawgGameId)
          .single();
      return Avaliacao.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<Avaliacao> upsertAvaliacao(
    String usuarioId,
    int rawgGameId, {
    required int nota,
    String? comentario,
    String? rawgSlug,
  }) async {
    try {
      // Tenta atualizar
      final response = await _client
          .from('avaliacoes')
          .update({
            'nota': nota,
            'comentario': comentario,
            'atualizado_em': DateTime.now().toIso8601String(),
          })
          .eq('usuario_id', usuarioId)
          .eq('rawg_game_id', rawgGameId)
          .select()
          .single();
      return Avaliacao.fromJson(response);
    } catch (e) {
      // Se não existe, cria
      final response = await _client
          .from('avaliacoes')
          .insert({
            'usuario_id': usuarioId,
            'rawg_game_id': rawgGameId,
            'nota': nota,
            'comentario': comentario,
            'rawg_slug': rawgSlug,
          })
          .select()
          .single();
      return Avaliacao.fromJson(response);
    }
  }

  Future<void> deleteAvaliacao(String usuarioId, int rawgGameId) async {
    await _client
        .from('avaliacoes')
        .delete()
        .eq('usuario_id', usuarioId)
        .eq('rawg_game_id', rawgGameId);
  }

  Future<List<Avaliacao>> getGameAvaliacoes(int rawgGameId) async {
    final response = await _client
        .from('avaliacoes')
        .select()
        .eq('rawg_game_id', rawgGameId)
        .order('criado_em', ascending: false);
    return (response as List).map((e) => Avaliacao.fromJson(e)).toList();
  }
}
