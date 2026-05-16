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
  // BIBLIOTECA (status de jogos)
  // ============================================================

  Future<List<Map<String, dynamic>>> getUserLibrary() async {
    final uid = currentUserId;
    if (uid == null) return [];

    final response = await _client
        .from('biblioteca')
        .select()
        .eq('user_id', uid);

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<void> updateGameStatus(String gameId, String status, String gameImage) async {
    final uid = currentUserId;
    if (uid == null) return;

    final dynamic parsedGameId = int.tryParse(gameId) ?? gameId;

    await _client.from('biblioteca').upsert({
      'user_id': uid,
      'game_id': parsedGameId,
      'status': status,
      'game_image': gameImage,
    }, onConflict: 'user_id, game_id');
  }

  Future<List<Map<String, dynamic>>> getLibraryByStatus(String status) async {
    final uid = currentUserId;
    if (uid == null) return [];

    final response = await _client
        .from('biblioteca')
        .select()
        .eq('user_id', uid)
        .eq('status', status);

    return List<Map<String, dynamic>>.from(response as List);
  }

  // ============================================================
  // AVALIAÇÕES
  // ============================================================

  Future<Avaliacao> upsertAvaliacao(
    int gameId, {
    required int nota,
    String? comentario,
    String? rawgSlug,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception("Usuário não autenticado");

    final data = {
      'user_id': uid,
      'game_id': gameId,
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

  Future<void> deleteAvaliacao(int gameId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _client
        .from('avaliacoes')
        .delete()
        .eq('user_id', uid)
        .eq('game_id', gameId);
  }
}
