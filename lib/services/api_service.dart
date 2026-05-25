import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// IDs de plataforma da RAWG API
// PC=4, PlayStation=18(PS4)/187(PS5), Xbox=1(XboxOne)/186(XboxSX), Nintendo=7(Switch), Mobile=21(Android)/3(iOS)
const Map<String, List<int>> kPlatformIds = {
  'PC': [4],
  'PlayStation': [18, 187],
  'Xbox': [1, 186],
  'Nintendo': [7],
  'Mobile': [21, 3],
};

// Valores de ordering aceitos pela RAWG
const Map<String, String> kOrderingValues = {
  'relevance': '-added',
  'rating': '-rating',
  'released': '-released',
};

class ApiService {
  final String _baseUrl = 'https://api.rawg.io/api';

  String get _apiKey {
    return dotenv.env['RAWG_API_KEY'] ?? 'COLE_SUA_CHAVE_RAWG_AQUI';
  }

  // Monta string de plataformas para o parâmetro &platforms=
  String _buildPlatformsParam(List<String> selectedPlatforms) {
    if (selectedPlatforms.isEmpty) return '';
    final ids = selectedPlatforms
        .expand((p) => kPlatformIds[p] ?? [])
        .toList();
    return ids.isEmpty ? '' : '&platforms=${ids.join(',')}';
  }

  // Jogos populares — ordenados por rating geral
  Future<List<dynamic>> getPopularGames({int page = 1}) async {
    try {
      final response = await http.get(Uri.parse(
          '$_baseUrl/games?key=$_apiKey&page_size=20&page=$page&ordering=-rating'));
      if (response.statusCode == 200) {
        return json.decode(response.body)['results'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Lançamentos recentes — últimos 12 meses, ordenados por data
  Future<List<dynamic>> getRecentGames({int page = 1}) async {
    try {
      final now = DateTime.now();
      final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
      final from =
          '${oneYearAgo.year}-${oneYearAgo.month.toString().padLeft(2, '0')}-${oneYearAgo.day.toString().padLeft(2, '0')}';
      final to =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final response = await http.get(Uri.parse(
          '$_baseUrl/games?key=$_apiKey&page_size=20&page=$page&ordering=-released&dates=$from,$to'));
      if (response.statusCode == 200) {
        return json.decode(response.body)['results'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Mais bem avaliados — ordenados por Metacritic
  Future<List<dynamic>> getTopRatedGames({int page = 1}) async {
    try {
      final response = await http.get(Uri.parse(
          '$_baseUrl/games?key=$_apiKey&page_size=20&page=$page&ordering=-metacritic&metacritic=80,100'));
      if (response.statusCode == 200) {
        return json.decode(response.body)['results'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Busca por nome — com suporte a plataformas e ordenação
  Future<List<dynamic>> searchGames(
    String query, {
    int page = 1,
    List<String> platforms = const [],
    String ordering = 'relevance',
  }) async {
    try {
      final platformParam = _buildPlatformsParam(platforms);
      final orderingParam = kOrderingValues[ordering] ?? '-added';
      final uri = '$_baseUrl/games?key=$_apiKey'
          '&search=$query'
          '&page_size=20'
          '&page=$page'
          '&ordering=$orderingParam'
          '$platformParam';
      final response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        return json.decode(response.body)['results'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Detalhes completos do jogo
  Future<Map<String, dynamic>> getGameDetails(int id) async {
    final response =
        await http.get(Uri.parse('$_baseUrl/games/$id?key=$_apiKey'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Falha ao carregar detalhes do jogo');
  }
}
