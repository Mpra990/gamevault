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

  // --- Estado das seções fixas ---
  List<dynamic> _popularGames = [];
  List<dynamic> _recentGames = [];
  List<dynamic> _topRatedGames = [];

  // --- Estado da busca ---
  List<dynamic> _allSearchGames = [];
  List<dynamic> _filteredSearchGames = [];
  bool _isSearching = false;
  int _searchPage = 1;
  bool _isLoadingMoreSearch = false;

  // --- Estado geral ---
  bool _isLoadingSections = true;

  // --- Estado dos filtros ---
  double _minRatingFilter = 0;
  final List<String> _allPlatforms = ['PC', 'PlayStation', 'Xbox', 'Nintendo', 'Mobile'];
  List<String> _selectedPlatforms = [];        // checkboxes
  String _selectedOrdering = 'relevance';       // radio button

  // Ícones por plataforma
  final Map<String, IconData> _platformIcons = {
    'PC': Icons.computer,
    'PlayStation': Icons.sports_esports,
    'Xbox': Icons.sports_esports_outlined,
    'Nintendo': Icons.games,
    'Mobile': Icons.smartphone,
  };

  // --- Paleta ---
  final Color _accentColor = const Color(0xFF00E5FF);
  final Color _surfaceColor = const Color(0xFF1A1D21);
  final Color _textColorSecondary = Colors.white60;

  @override
  void initState() {
    super.initState();
    _loadAllSections();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isSearching &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMoreSearch) {
      _loadMoreSearchResults();
    }
  }

  // ─── Carregamento ────────────────────────────────────────────────────────

  Future<void> _loadAllSections() async {
    setState(() => _isLoadingSections = true);
    try {
      final results = await Future.wait([
        _apiService.getPopularGames(),
        _apiService.getRecentGames(),
        _apiService.getTopRatedGames(),
      ]);
      if (!mounted) return;
      setState(() {
        _popularGames = results[0];
        _recentGames = results[1];
        _topRatedGames = results[2];
        _isLoadingSections = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingSections = false);
    }
  }

  Future<void> _searchGames(String query) async {
    if (query.trim().isEmpty) {
      _clearSearch();
      return;
    }
    setState(() {
      _isSearching = true;
      _isLoadingSections = true;
      _searchPage = 1;
      _allSearchGames = [];
      _filteredSearchGames = [];
    });
    try {
      final games = await _apiService.searchGames(
        query,
        page: _searchPage,
        platforms: _selectedPlatforms,
        ordering: _selectedOrdering,
      );
      if (!mounted) return;
      setState(() {
        _allSearchGames = games;
        _applyRatingFilterLocal();
        _isLoadingSections = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingSections = false);
    }
  }

  Future<void> _loadMoreSearchResults() async {
    setState(() => _isLoadingMoreSearch = true);
    _searchPage++;
    try {
      final games = await _apiService.searchGames(
        _searchController.text,
        page: _searchPage,
        platforms: _selectedPlatforms,
        ordering: _selectedOrdering,
      );
      if (!mounted) return;
      if (games.isNotEmpty) {
        setState(() {
          _allSearchGames.addAll(games);
          _applyRatingFilterLocal();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingMoreSearch = false);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _allSearchGames = [];
      _filteredSearchGames = [];
      _minRatingFilter = 0;
      _selectedPlatforms = [];
      _selectedOrdering = 'relevance';
    });
    if (_popularGames.isEmpty) _loadAllSections();
  }

  // ─── Filtros ─────────────────────────────────────────────────────────────

  // Aplica filtro de nota localmente (após receber da API)
  void _applyRatingFilterLocal() {
    if (_minRatingFilter == 0) {
      _filteredSearchGames = List.from(_allSearchGames);
      return;
    }
    _filteredSearchGames = _allSearchGames.where((game) {
      if (game == null) return false;
      final raw = double.tryParse(game['rating']?.toString() ?? '0') ?? 0;
      final rating = raw <= 5 ? raw * 20 : raw;
      return rating >= _minRatingFilter;
    }).toList();
  }

  // Retorna true se algum filtro está ativo
  bool get _hasActiveFilters =>
      _selectedPlatforms.isNotEmpty ||
      _selectedOrdering != 'relevance' ||
      _minRatingFilter > 0;

  // Abre o BottomSheet de filtros
  void _openFilterSheet() {
    // Cópias temporárias para o modal (não aplica até o usuário confirmar)
    double tempRating = _minRatingFilter;
    List<String> tempPlatforms = List.from(_selectedPlatforms);
    String tempOrdering = _selectedOrdering;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Handle + cabeçalho ──────────────────────────────
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 4),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filtros',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Botão limpar tudo
                          TextButton(
                            onPressed: () => setModal(() {
                              tempRating = 0;
                              tempPlatforms = [];
                              tempOrdering = 'relevance';
                            }),
                            child: Text(
                              'Limpar tudo',
                              style: TextStyle(color: _accentColor, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(color: Colors.white12),

                    // ── Plataformas (checkboxes) ────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Text(
                        'PLATAFORMA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _textColorSecondary,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    ..._allPlatforms.map((platform) {
                      final isChecked = tempPlatforms.contains(platform);
                      return InkWell(
                        onTap: () => setModal(() {
                          if (isChecked) {
                            tempPlatforms.remove(platform);
                          } else {
                            tempPlatforms.add(platform);
                          }
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 2),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isChecked,
                                onChanged: (v) => setModal(() {
                                  if (v == true) {
                                    tempPlatforms.add(platform);
                                  } else {
                                    tempPlatforms.remove(platform);
                                  }
                                }),
                                activeColor: _accentColor,
                                checkColor: Colors.black,
                                side: const BorderSide(
                                    color: Colors.white38, width: 1.5),
                              ),
                              Icon(
                                _platformIcons[platform],
                                color: isChecked ? _accentColor : Colors.white54,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                platform,
                                style: TextStyle(
                                  color: isChecked
                                      ? Colors.white
                                      : Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 8),
                    const Divider(color: Colors.white12),

                    // ── Ordenação (radio buttons) ───────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Text(
                        'ORDENAR POR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _textColorSecondary,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    ...[
                      ('relevance', 'Relevância', Icons.trending_up),
                      ('rating', 'Nota', Icons.star_outline),
                      ('released', 'Data de lançamento', Icons.calendar_today_outlined),
                    ].map((entry) {
                      final (value, label, icon) = entry;
                      final isSelected = tempOrdering == value;
                      return InkWell(
                        onTap: () => setModal(() => tempOrdering = value),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 2),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: value,
                                groupValue: tempOrdering,
                                onChanged: (v) =>
                                    setModal(() => tempOrdering = v!),
                                activeColor: _accentColor,
                              ),
                              Icon(
                                icon,
                                color:
                                    isSelected ? _accentColor : Colors.white54,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                label,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 8),
                    const Divider(color: Colors.white12),

                    // ── Nota mínima (slider) ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'NOTA MÍNIMA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _textColorSecondary,
                              letterSpacing: 1.4,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: tempRating > 0
                                  ? _accentColor.withOpacity(0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: tempRating > 0
                                    ? _accentColor
                                    : Colors.white24,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              tempRating == 0
                                  ? 'Qualquer'
                                  : '≥ ${tempRating.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: tempRating > 0
                                    ? _accentColor
                                    : Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Slider(
                        value: tempRating,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        activeColor: _accentColor,
                        inactiveColor: Colors.white24,
                        onChanged: (v) => setModal(() => tempRating = v),
                      ),
                    ),

                    // ── Botões de ação ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white24),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancelar',
                                  style: TextStyle(color: Colors.white54)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentColor,
                                foregroundColor: Colors.black,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                // Aplica os filtros e relança a busca
                                setState(() {
                                  _minRatingFilter = tempRating;
                                  _selectedPlatforms = tempPlatforms;
                                  _selectedOrdering = tempOrdering;
                                });
                                if (_isSearching &&
                                    _searchController.text.isNotEmpty) {
                                  _searchGames(_searchController.text);
                                }
                              },
                              child: const Text(
                                'Aplicar filtros',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      debugPrint('Erro ao sair: $e');
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  int _displayRating(dynamic game) {
    final raw = double.tryParse(game['rating']?.toString() ?? '0') ?? 0;
    return raw <= 5 ? (raw * 20).round() : raw.round();
  }

  // ─── Widgets de card ─────────────────────────────────────────────────────

  Widget _buildHorizontalCard(dynamic game) {
    if (game == null) return const SizedBox.shrink();
    final rating = _displayRating(game);
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => DetailsScreen(gameId: game['id']))),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(children: [
            Positioned.fill(
              child: Image.network(
                game['background_image'] ??
                    'https://via.placeholder.com/400x600',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    color: _surfaceColor,
                    child:
                        const Icon(Icons.broken_image, color: Colors.white24)),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFF00E054),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(
                  rating == 0 ? 'N/A' : rating.toString(),
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 11),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Text(game['name'] ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildGridCard(dynamic game) {
    if (game == null) return const SizedBox.shrink();
    final rating = _displayRating(game);
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => DetailsScreen(gameId: game['id']))),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(children: [
            Positioned.fill(
              child: Image.network(
                game['background_image'] ??
                    'https://via.placeholder.com/400x600',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    color: _surfaceColor,
                    child:
                        const Icon(Icons.broken_image, color: Colors.white24)),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFF00E054),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(
                  rating == 0 ? 'N/A' : rating.toString(),
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 11),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Text(game['name'] ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── Seções ──────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _textColorSecondary,
                  letterSpacing: 1.5)),
          Icon(Icons.chevron_right, color: _accentColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildHorizontalList(List<dynamic> games) {
    if (games.isEmpty) {
      return SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator(color: _accentColor)));
    }
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: games.length,
        itemBuilder: (_, i) => _buildHorizontalCard(games[i]),
      ),
    );
  }

  Widget _buildSectionsView() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader('🔥 Jogos Populares'),
      _buildHorizontalList(_popularGames),
      _buildSectionHeader('🆕 Lançamentos Recentes'),
      _buildHorizontalList(_recentGames),
      _buildSectionHeader('⭐ Mais Bem Avaliados'),
      _buildHorizontalList(_topRatedGames),
      const SizedBox(height: 32),
    ]);
  }

  Widget _buildSearchResultsView() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('RESULTADOS',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _textColorSecondary,
                    letterSpacing: 1.5)),
            // Chips de filtros ativos
            if (_hasActiveFilters)
              Row(children: [
                if (_selectedPlatforms.isNotEmpty)
                  _filterChip('${_selectedPlatforms.length} plataforma(s)'),
                if (_selectedOrdering != 'relevance')
                  _filterChip(_selectedOrdering == 'rating'
                      ? 'Por nota'
                      : 'Por data'),
                if (_minRatingFilter > 0)
                  _filterChip('≥${_minRatingFilter.toStringAsFixed(0)}'),
              ]),
          ],
        ),
      ),
      if (_filteredSearchGames.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(
              child: Text('Nenhum jogo encontrado.',
                  style: TextStyle(color: Colors.white54))),
        )
      else
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 24),
            itemCount: _filteredSearchGames.length,
            itemBuilder: (_, i) => _buildGridCard(_filteredSearchGames[i]),
          ),
        ),
      if (_isLoadingMoreSearch)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator(color: _accentColor)),
        ),
      const SizedBox(height: 32),
    ]);
  }

  Widget _filterChip(String label) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentColor.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: _accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  // ─── Build principal ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('GameVault'),
          const SizedBox(width: 8),
          Icon(Icons.sports_esports, color: _accentColor),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, size: 26),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: Column(children: [
          DrawerHeader(
            decoration: BoxDecoration(color: _surfaceColor),
            child: Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.sports_esports, color: _accentColor, size: 32),
                const SizedBox(width: 12),
                const Text('GAMEVAULT',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5)),
              ]),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.white),
            title: const Text('Início', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title: const Text('Configurações',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          const Spacer(),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Sair da Conta',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              _signOut();
            },
          ),
          const SizedBox(height: 24),
        ]),
      ),
      body: RefreshIndicator(
        color: _accentColor,
        onRefresh: () async {
          if (_isSearching) {
            await _searchGames(_searchController.text);
          } else {
            await _loadAllSections();
          }
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Barra de busca + botão de filtro ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: _searchGames,
                      style: const TextStyle(color: Colors.white),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 0),
                        hintText: 'Busca de jogos pelo nome...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        fillColor: _surfaceColor,
                        filled: true,
                        prefixIcon: Icon(Icons.search, color: _accentColor),
                        suffixIcon: _isSearching
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                color: _accentColor,
                                onPressed: _clearSearch,
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                // Botão de filtro — sempre visível, badge quando há filtros ativos
                const SizedBox(width: 12),
                Stack(children: [
                  Container(
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      color: _hasActiveFilters
                          ? _accentColor.withOpacity(0.15)
                          : _surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: _hasActiveFilters
                          ? Border.all(
                              color: _accentColor.withOpacity(0.5), width: 1)
                          : null,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.tune,
                          color: _hasActiveFilters
                              ? _accentColor
                              : _accentColor),
                      iconSize: 26,
                      onPressed: _openFilterSheet,
                    ),
                  ),
                  // Badge de contagem de filtros ativos
                  if (_hasActiveFilters)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            [
                              if (_selectedPlatforms.isNotEmpty) 1,
                              if (_selectedOrdering != 'relevance') 1,
                              if (_minRatingFilter > 0) 1,
                            ].length.toString(),
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ]),
              ]),
            ),

            // ── Conteúdo ─────────────────────────────────────────────────
            if (_isLoadingSections)
              SizedBox(
                  height: 400,
                  child: Center(
                      child: CircularProgressIndicator(color: _accentColor)))
            else if (_isSearching)
              _buildSearchResultsView()
            else
              _buildSectionsView(),
          ]),
        ),
      ),
    );
  }
}
