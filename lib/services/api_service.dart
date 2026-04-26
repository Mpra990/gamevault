import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/game_model.dart';

class ApiService {
  late final String _baseUrl;
  late final String _apiKey;

  ApiService() {
    _baseUrl = dotenv.get('API_BASE_URL', fallback: 'https://api.rawg.io/api');
    _apiKey = dotenv.get('API_KEY', fallback: '');
  }

  Future<List<Game>> fetchPopularGames() async {
    final response = await http.get(
      Uri.parse("$_baseUrl/games?key=$_apiKey&page_size=10"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> results = data['results'];
      return results.map((json) => Game.fromJson(json)).toList();
    } else {
      throw Exception("Erro ao carregar jogos");
    }
  }

  Future<List<Game>> fetchGamesBySearch(String query, {int pageSize = 20}) async {
    final response = await http.get(
      Uri.parse("$_baseUrl/games?key=$_apiKey&search=$query&page_size=$pageSize"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> results = data['results'];
      return results.map((json) => Game.fromJson(json)).toList();
    } else {
      throw Exception("Erro ao buscar jogos");
    }
  }

  Future<Map<String, dynamic>> fetchGameDetails(int gameId) async {
    final response = await http.get(
      Uri.parse("$_baseUrl/games/$gameId?key=$_apiKey"),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Erro ao buscar detalhes do jogo");
    }
  }
}
