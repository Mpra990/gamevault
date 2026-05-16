import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> _allGames = []; 
  List<dynamic> _filteredGames = []; 
  bool _isLoading = true;
  bool _isLoadMore = false;
  int _currentPage = 1;
  double _minRatingFilter = 0; 

  @override
  void initState() {
    super.initState();
    _loadInitialGames();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300 && !_isLoadMore && !_isLoading) {
      _loadMoreGames();
    }
  }

  Future<void> _loadInitialGames() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
    });
    try {
      final games = await _apiService.getPopularGames(page: _currentPage);
      setState(() {
        _allGames = games;
        _filteredGames = List.from(_allGames); 
        _minRatingFilter = 0; 
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreGames() async {
    setState(() => _isLoadMore = true);
    _currentPage++;
    try {
      List<dynamic> nextGames;
      if (_searchController.text.isEmpty) {
        nextGames = await _apiService.getPopularGames(page: _currentPage);
      } else {
        nextGames = await _apiService.searchGames(_searchController.text, page: _currentPage);
      }

      if (nextGames.isNotEmpty) {
        setState(() {
          _allGames.addAll(nextGames);
          _applyLocalRatingFilter(_minRatingFilter);
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar mais jogos: $e");
    } finally {
      setState(() => _isLoadMore = false);
    }
  }

  Future<void> _searchGames(String query) async {
    if (query.isEmpty) {
      _loadInitialGames();
      return;
    }
    setState(() {
      _isLoading = true;
      _currentPage = 1;
    });
    try {
      final games = await _apiService.searchGames(query, page: _currentPage);
      setState(() {
        _allGames = games;
        _filteredGames = List.from(_allGames);
        _minRatingFilter = 0; 
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyLocalRatingFilter(double minRating) {
    setState(() {
      _minRatingFilter = minRating;
      if (minRating == 0) {
        _filteredGames = List.from(_allGames);
        return;
      }
      _filteredGames = _allGames.where((game) {
        if (game == null) return false;
        double rating = 0;
        if (game['rating'] != null) {
          double rawRating = double.tryParse(game['rating'].toString()) ?? 0;
          rating = rawRating <= 5 ? rawRating * 20 : rawRating;
        }
        return rating >= minRating;
      }).toList();
    });
  }

  void _openFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double tempRating = _minRatingFilter; 
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1C2228),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Filtro de Nota", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Nota mínima: ", style: TextStyle(color: Colors.white70, fontSize: 16)),
                      Text(tempRating.toStringAsFixed(0), style: const TextStyle(color: Color(0xFFD500F9), fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  Slider(
                    value: tempRating,
                    min: 0, max: 100, divisions: 100,
                    activeColor: const Color(0xFFD500F9), inactiveColor: Colors.white24,
                    onChanged: (value) => setModalState(() => tempRating = value),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
              actions: [
                Row(
                  children: [
                    Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.white38)))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _applyLocalRatingFilter(tempRating); 
                          Navigator.pop(context);
                        },
                        child: const Text("Aplicar"),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Text("GameVault"), SizedBox(width: 8), Icon(Icons.sports_esports, color: Color(0xFFD500F9))],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.person_outline, size: 26), onPressed: () => Navigator.pushNamed(context, '/profile')),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInitialGames,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: _searchGames,
                            decoration: InputDecoration(
                              hintText: "Busca de jogos pelo nome...",
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _loadInitialGames(); }),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(color: const Color(0xFF1C2228), borderRadius: BorderRadius.circular(12)),
                          child: IconButton(icon: const Icon(Icons.tune, color: Color(0xFFD500F9)), onPressed: _openFilterDialog),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("EXPLORAR JOGOS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white60, letterSpacing: 1.5)),
                        if (_minRatingFilter > 0) Text("Nota ≥ ${_minRatingFilter.toStringAsFixed(0)}", style: const TextStyle(fontSize: 12, color: Color(0xFFD500F9), fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 16, mainAxisSpacing: 16),
                      itemCount: _filteredGames.length,
                      itemBuilder: (context, index) {
                        final game = _filteredGames[index];
                        if (game == null) return const SizedBox.shrink();
                        double rawRating = game['rating'] != null ? double.parse(game['rating'].toString()) : 0;
                        
                        // O PONTO E VÍRGULA QUE FALTAVA ESTÁ BEM AQUI NESSA LINHA ABAIXO!
                        int displayRating = rawRating <= 5 ? (rawRating * 20).round() : rawRating.round();

                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsScreen(gameId: game['id']))),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.network(game['background_image'] ?? 'https://via.placeholder.com/400x600', fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image)),
                                ),
                                Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])))),
                                Positioned(
                                  top: 12, right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(color: const Color(0xFF00E054), borderRadius: BorderRadius.circular(6)),
                                    child: Text(displayRating == 0 ? 'N/A' : displayRating.toString(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                                  ),
                                ),
                                Positioned(bottom: 12, left: 12, right: 12, child: Text(game['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    if (_isLoadMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator(color: Color(0xFFD500F9))),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}