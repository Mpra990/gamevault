import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/game_model.dart';
// import '../models/game_model.dart';

class ApiService {
  final String _baseUrl = "https://api.rawg.io/api";
  final String _apiKey = "SUA_CHAVE_AQUI"; // Coloque sua chave aqui

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
}
