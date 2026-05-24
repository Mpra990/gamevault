import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // --- Paleta de Cores Moderna (inspirada na Epic) ---
  final Color _accentColor = const Color(0xFF00E5FF); // Azul Neon
  final Color _surfaceColor = const Color(0xFF1A1D21); // Cinza Escuro Premium
  final Color _textColorSecondary = Colors.white60; // Cor secundária para textos

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

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      debugPrint("Erro ao sair: $e");
    }
  }

  void _openFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double tempRating = _minRatingFilter; 
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: _surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Filtro de Nota", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Nota mínima: ", style: TextStyle(color: Colors.white70, fontSize: 16)),
                      Text(tempRating.toStringAsFixed(0), style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  Slider(
                    value: tempRating,
                    min: 0, max: 100, divisions: 100,
                    activeColor: _accentColor, inactiveColor: Colors.white24,
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          _applyLocalRatingFilter(tempRating); 
                          Navigator.pop(context);
                        },
                        child: const Text("Aplicar", style: TextStyle(fontWeight: FontWeight.bold)),
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
      backgroundColor: Colors.black, // Fundo preto puro para visual mais premium
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [const Text("GameVault"), const SizedBox(width: 8), Icon(Icons.sports_esports, color: _accentColor)],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.person_outline, size: 26), onPressed: () => Navigator.pushNamed(context, '/profile')),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: _surfaceColor),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sports_esports, color: _accentColor, size: 32),
                    const SizedBox(width: 12),
                    const Text(
                      "GAMEVAULT",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white),
              title: const Text("Início", style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text("Configurações", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            const Spacer(),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Sair da Conta", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _signOut();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _accentColor))
          : RefreshIndicator(
              color: _accentColor,
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
                          child: SizedBox(
                            height: 54, // Altura fixada para alinhar perfeitamente
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: _searchGames,
                              style: const TextStyle(color: Colors.white), // Texto digitado na cor branca
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                hintText: "Busca de jogos pelo nome...",
                                hintStyle: const TextStyle(color: Colors.white38),
                                fillColor: _surfaceColor, 
                                filled: true,
                                prefixIcon: Icon(Icons.search, color: _accentColor),
                                suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _loadInitialGames(); }, color: _accentColor,),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), 
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 54, // Exatamente a mesma altura da barra de busca
                          width: 54,
                          decoration: BoxDecoration(color: _surfaceColor, borderRadius: BorderRadius.circular(12)),
                          child: IconButton(
                            icon: Icon(Icons.tune, color: _accentColor), 
                            onPressed: _openFilterDialog, 
                            iconSize: 26, 
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("EXPLORAR JOGOS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textColorSecondary, letterSpacing: 1.5)),
                        if (_minRatingFilter > 0) Text("Nota ≥ ${_minRatingFilter.toStringAsFixed(0)}", style: TextStyle(fontSize: 12, color: _accentColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 16, mainAxisSpacing: 24), 
                      itemCount: _filteredGames.length,
                      itemBuilder: (context, index) {
                        final game = _filteredGames[index];
                        if (game == null) return const SizedBox.shrink();
                        double rawRating = game['rating'] != null ? double.parse(game['rating'].toString()) : 0;
                        
                        int displayRating = rawRating <= 5 ? (rawRating * 20).round() : rawRating.round();

                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsScreen(gameId: game['id']))),
                          child: Container( 
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [ 
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  spreadRadius: 1,
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.network(game['background_image'] ?? 'https://via.placeholder.com/400x600', fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, color: Colors.white24,)),
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
                          ),
                        );
                      },
                    ),
                    if (_isLoadMore)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32), 
                        child: Center(child: CircularProgressIndicator(color: _accentColor)),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}