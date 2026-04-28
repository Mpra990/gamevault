import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/game_model.dart';

class ApiService {
  final String _apiKey = dotenv.env['RAWG_API_KEY'] ?? "";
  final String _baseUrl = "https://api.rawg.io/api";

  Future<List<Game>> fetchPopularGames() async {
    final url = "$_baseUrl/games?key=$_apiKey&page_size=10";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List games = data['results'];
      return games.map((json) => Game.fromJson(json)).toList();
    } else {
      throw Exception("Erro ao carregar jogos populares");
    }
  }

  Future<List<Game>> fetchGamesBySearch(String query) async {
    final url = "$_baseUrl/games?key=$_apiKey&search=$query&page_size=20";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List games = data['results'];
      return games.map((json) => Game.fromJson(json)).toList();
    } else {
      throw Exception("Erro na busca de jogos");
    }
  }

  // ESTA É A FUNÇÃO QUE ESTAVA FALTANDO:
  Future<Map<String, dynamic>> fetchGameDetails(int id) async {
    final url = "$_baseUrl/games/$id?key=$_apiKey";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Erro ao buscar detalhes do jogo");
    }
  }
}
