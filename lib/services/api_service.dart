import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  final String _baseUrl = 'https://api.rawg.io/api';
  
  String get _apiKey {
    return dotenv.env['RAWG_API_KEY'] ?? 'COLE_SUA_CHAVE_RAWG_AQUI';
  }

  Future<List<dynamic>> getPopularGames({int page = 1}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/games?key=$_apiKey&page_size=20&page=$page'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['results'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> searchGames(String query, {int page = 1}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/games?key=$_apiKey&search=$query&page_size=20&page=$page'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['results'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getGameDetails(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/games/$id?key=$_apiKey'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Falha ao carregar detalhes do jogo');
  }
}