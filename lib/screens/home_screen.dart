import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game_model.dart';
import 'details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String _apiKey = "ef722b1e87a94f6c96fa738a6bfa9100";
  List<Game> _games = [];
  bool _isLoading = false;
  double _minRating = 0;
  final TextEditingController _searchController = TextEditingController();

  Color _getRatingColor(double rating) {
    if (rating >= 75) return Colors.green;
    if (rating >= 50) return Colors.orange;
    return Colors.red;
  }

  Future<void> _fetchGames({String query = ""}) async {
    setState(() => _isLoading = true);
    String url = "https://api.rawg.io/api/games?key=$_apiKey&page_size=20";
    if (query.isNotEmpty) url += "&search=$query";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];
        setState(() {
          _games = results.map((j) => Game.fromJson(j)).toList();
        });
      }
    } catch (e) {
      debugPrint("Erro: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openGameDetails(Game game) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.purpleAccent),
      ),
    );

    final url = "https://api.rawg.io/api/games/${game.id}?key=$_apiKey";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        game.description =
            data['description_raw'] ?? "Sem descrição disponível.";
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailsScreen(game: game)),
        );
      }
    } catch (e) {
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchGames();
  }

  @override
  Widget build(BuildContext context) {
    final filteredGames = _games.where((g) => g.rating >= _minRating).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "GameVault 🎮",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[900],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Buscar jogo...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.purpleAccent,
                ),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) => _fetchGames(query: value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Column(
              children: [
                Text(
                  "Nota mínima: ${_minRating.toInt()}",
                  style: const TextStyle(color: Colors.white),
                ),
                Slider(
                  value: _minRating,
                  min: 0,
                  max: 100,
                  activeColor: Colors.purpleAccent,
                  onChanged: (val) => setState(() => _minRating = val),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.purpleAccent,
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: filteredGames.length,
                    itemBuilder: (context, index) {
                      final game = filteredGames[index];
                      return GestureDetector(
                        onTap: () => _openGameDetails(game),
                        child: Card(
                          color: Colors.grey[850],
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    Image.network(
                                      game.backgroundImage,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getRatingColor(game.rating),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          game.rating.toInt().toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Text(
                                  game.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
