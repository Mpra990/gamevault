import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/game_status.dart';
import '../services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _topFavorites = [];
  List<Map<String, dynamic>> _playedGames = [];
  List<Map<String, dynamic>> _wishlistGames = [];
  List<Map<String, dynamic>> _droppedGames = [];
  bool _isLoading = true;
  String _username = "PLAYER";
  String _avatarUrl = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfileAndLists();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileAndLists() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final profileData = await _supabase.from('profiles').select().eq('id', user.id).maybeSingle();
      if (profileData != null) {
        _username = profileData['username'] ?? user.email?.split('@')[0].toUpperCase();
        _avatarUrl = profileData['avatar_url'] ?? "";
      } else {
        _username = user.email?.split('@')[0].toUpperCase() ?? "PLAYER";
      }
      final favoritesData = await _supabase.from('favoritos').select().eq('user_id', user.id).limit(5);
      final playedData = await _supabaseService.getLibraryByStatus(GameStatus.jaJoguei);
      final wishlistData = await _supabaseService.getLibraryByStatus(GameStatus.pretendeJogar);
      final droppedData = await _supabaseService.getLibraryByStatus(GameStatus.dropado);
      
      if (!mounted) return;
      setState(() {
        _topFavorites = List<Map<String, dynamic>>.from(favoritesData);
        _playedGames = List<Map<String, dynamic>>.from(playedData);
        _wishlistGames = List<Map<String, dynamic>>.from(wishlistData);
        _droppedGames = List<Map<String, dynamic>>.from(droppedData);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar dados do perfil: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Função para evitar erro de tela quebrada caso a imagem venha vazia
  String _getValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return 'https://via.placeholder.com/400x600?text=Sem+Capa';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PERFIL GAMER"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings), 
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/settings');
              if (result == true) { 
                setState(() => _isLoading = true); 
                _loadProfileAndLists(); 
              }
            }
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD500F9)))
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24.0), color: const Color(0xFF1C2228),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 36, backgroundColor: const Color(0xFFD500F9), 
                                backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                                child: _avatarUrl.isEmpty 
                                  ? Text(_username.isNotEmpty ? _username[0].toUpperCase() : "P", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)) 
                                  : null,
                              ),
                              const SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _buildStatColumn(_playedGames.length.toString(), "JOGADOS"), const SizedBox(width: 20),
                                      _buildStatColumn(_wishlistGames.length.toString(), "PRETENDO"), const SizedBox(width: 20),
                                      _buildStatColumn(_droppedGames.length.toString(), "DROPADOS"),
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("TOP 5 FAVORITOS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white60)),
                              const SizedBox(height: 12),
                              _topFavorites.isEmpty
                                  ? const Text("Nenhum favorito selecionado.", style: TextStyle(color: Colors.white24))
                                  : SizedBox(
                                      height: 140,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal, 
                                        itemCount: _topFavorites.length,
                                        itemBuilder: (context, index) {
                                          final imageUrl = _getValidImageUrl(_topFavorites[index]['game_image']);
                                          return Container(
                                            width: 95, 
                                            margin: const EdgeInsets.only(right: 10), 
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  color: const Color(0xFF1C2228),
                                                  child: const Icon(Icons.broken_image, color: Colors.white24),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true, 
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController, 
                        tabs: [Tab(text: GameStatus.jaJoguei), const Tab(text: "Pretendo"), const Tab(text: "Dropados")]
                      )
                    )
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController, 
                children: [
                  _buildTabGrid(_playedGames), 
                  _buildTabGrid(_wishlistGames), 
                  _buildTabGrid(_droppedGames)
                ]
              ),
            ),
    );
  }

  Widget _buildTabGrid(List<Map<String, dynamic>> gamesList) {
    if (gamesList.isEmpty) return const Center(child: Text("Nenhum jogo nesta categoria.", style: TextStyle(color: Colors.white38)));
    return GridView.builder(
      padding: const EdgeInsets.all(16), 
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.7, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: gamesList.length,
      itemBuilder: (context, index) {
        final imageUrl = _getValidImageUrl(gamesList[index]['game_image']);
        return ClipRRect(
          borderRadius: BorderRadius.circular(8), 
          child: Image.network(
            imageUrl, 
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF1C2228),
              child: const Icon(Icons.broken_image, color: Colors.white24),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String value, String label) => Column(children: [Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold))]);
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(color: const Color(0xFF101418), child: _tabBar);
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}