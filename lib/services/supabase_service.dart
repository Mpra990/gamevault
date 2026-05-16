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

    await Supabase.initialize(url: url, anonKey: anonKey);

    _client = Supabase.instance.client;
  }

  SupabaseClient get client => _client;

  // ============================================================
  // USUÁRIOS (Sincronizado com Auth)
  // ============================================================

  // Retorna o ID do usuário que está logado no momento
  String? get currentUserId => _client.auth.currentUser?.id;

  Future<AppUser?> getUserProfile() async {
    final id = currentUserId;
    if (id == null) return null;

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

  // Atualiza perfil (Username/Avatar)
  Future<void> updateUserProfile({String? username, String? avatarUrl}) async {
    final id = currentUserId;
    if (id == null) return;

    await _client
        .from('usuarios')
        .update({
          'username': username,
          'avatar_url': avatarUrl,
          'atualizado_em': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  // ============================================================
  // FAVORITOS (Nova Tabela)
  // ============================================================

  Future<void> toggleFavorite(int gameId, String name, String? image) async {
    final uid = currentUserId;
    if (uid == null) return;

    final isFav = await isGameFavorite(gameId);

    if (isFav) {
      await _client
          .from('favoritos')
          .delete()
          .eq('user_id', uid)
          .eq('game_id', gameId);
    } else {
      await _client.from('favoritos').insert({
        'user_id': uid,
        'game_id': gameId,
        'game_name': name,
        'game_image': image,
      });
    }
  }

  Future<bool> isGameFavorite(int gameId) async {
    final uid = currentUserId;
    if (uid == null) return false;

    final response = await _client
        .from('favoritos')
        .select()
        .eq('user_id', uid)
        .eq('game_id', gameId);

    return (response as List).isNotEmpty;
  }

  Future<List<dynamic>> getUserFavorites() async {
    final uid = currentUserId;
    if (uid == null) return [];

    return await _client
        .from('favoritos')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
  }

  // ============================================================
  // STATUS JOGO (Jogando, Zerado, etc)
  // ============================================================

  Future<List<StatusJogo>> getUserGameStatus() async {
    final uid = currentUserId;
    if (uid == null) return [];

    final response = await _client
        .from('status_jogo')
        .select()
        .eq('usuario_id', uid);
    return (response as List).map((e) => StatusJogo.fromJson(e)).toList();
  }

  Future<StatusJogo?> getGameStatus(int rawgGameId) async {
    final uid = currentUserId;
    if (uid == null) return null;

    try {
      final response = await _client
          .from('status_jogo')
          .select()
          .eq('usuario_id', uid)
          .eq('rawg_game_id', rawgGameId)
          .single();
      return StatusJogo.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<StatusJogo> updateGameStatus(
    int rawgGameId,
    StatusJogoEnum status, {
    String? rawgSlug,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception("Usuário não autenticado");

    final data = {
      'usuario_id': uid,
      'rawg_game_id': rawgGameId,
      'rawg_slug': rawgSlug,
      'status': status.value,
      'atualizado_em': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('status_jogo')
        .upsert(data) // Upsert faz o Update ou Insert automaticamente
        .select()
        .single();

    return StatusJogo.fromJson(response);
  }

  // ============================================================
  // AVALIAÇÕES
  // ============================================================

  Future<Avaliacao> upsertAvaliacao(
    int rawgGameId, {
    required int nota,
    String? comentario,
    String? rawgSlug,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception("Usuário não autenticado");

    final data = {
      'usuario_id': uid,
      'rawg_game_id': rawgGameId,
      'nota': nota,
      'comentario': comentario,
      'rawg_slug': rawgSlug,
      'atualizado_em': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('avaliacoes')
        .upsert(data)
        .select()
        .single();

    return Avaliacao.fromJson(response);
  }

  Future<void> deleteAvaliacao(int rawgGameId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _client
        .from('avaliacoes')
        .delete()
        .eq('usuario_id', uid)
        .eq('rawg_game_id', rawgGameId);
  }
}
