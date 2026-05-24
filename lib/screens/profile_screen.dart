import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  late TabController _tabController;
  
  List<Map<String, dynamic>> _topFavorites = [];
  List<Map<String, dynamic>> _playedGames = [];
  List<Map<String, dynamic>> _wishlistGames = [];
  List<Map<String, dynamic>> _droppedGames = [];
  bool _isLoading = true;
  String _username = "PLAYER";
  String _avatarUrl = "";

  final Color _accentColor = const Color(0xFF00E5FF);
  final Color _surfaceColor = const Color(0xFF1A1D21);

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
      final libraryData = await _supabase.from('biblioteca').select().eq('user_id', user.id);
      
      if (!mounted) return;
      setState(() {
        _topFavorites = List<Map<String, dynamic>>.from(favoritesData);
        _playedGames = libraryData.where((g) => g['status'] == 'Já joguei').toList();
        _wishlistGames = libraryData.where((g) => g['status'] == 'Pretendo jogar').toList();
        _droppedGames = libraryData.where((g) => g['status'] == 'Dropado').toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar dados do perfil: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return 'https://via.placeholder.com/400x600?text=Sem+Capa';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("PERFIL GAMER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _accentColor))
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24.0), 
                          color: _surfaceColor,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 36, backgroundColor: _accentColor, 
                                backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                                child: _avatarUrl.isEmpty 
                                  ? Text(_username.isNotEmpty ? _username[0].toUpperCase() : "P", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)) 
                                  : null,
                              ),
                              const SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
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
                              const Text("TOP 5 FAVORITOS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white60, letterSpacing: 1.2)),
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
                                            decoration: BoxDecoration(
                                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  color: _surfaceColor,
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
                        indicatorColor: _accentColor,
                        labelColor: _accentColor,
                        unselectedLabelColor: Colors.white38,
                        tabs: const [Tab(text: "Já joguei"), Tab(text: "Pretendo"), Tab(text: "Dropados")]
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.7, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: gamesList.length,
      itemBuilder: (context, index) {
        final imageUrl = _getValidImageUrl(gamesList[index]['game_image']);
        return Container(
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 3))]
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8), 
            child: Image.network(
              imageUrl, 
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: _surfaceColor,
                child: const Icon(Icons.broken_image, color: Colors.white24),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String value, String label) => Column(children: [Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), Text(label, style: const TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold))]);
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(color: Colors.black, child: _tabBar);
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}