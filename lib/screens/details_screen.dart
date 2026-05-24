import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';

class DetailsScreen extends StatefulWidget {
  final int gameId;
  const DetailsScreen({super.key, required this.gameId});
  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final ApiService _apiService = ApiService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Map<String, dynamic>? _gameDetails;
  bool _isLoading = true;
  bool _isFavorite = false;
  String _currentStatus = 'Nenhum';
  int _userStars = 0;

  final Color _accentColor = const Color(0xFF00E5FF);
  final Color _surfaceColor = const Color(0xFF1A1D21);

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    try {
      final details = await _apiService.getGameDetails(widget.gameId);
      if (!mounted) return;
      setState(() => _gameDetails = details);
      await _checkUserRelations();
    } catch (e) {
      debugPrint("Erro: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUserRelations() async {
    final user = _supabase.auth.currentUser;
    if (user == null || _gameDetails == null) return;
    try {
      final favResponse = await _supabase.from('favoritos').select().eq('user_id', user.id).eq('game_id', widget.gameId).maybeSingle();
      final statusResponse = await _supabase.from('biblioteca').select().eq('user_id', user.id).eq('game_id', widget.gameId).maybeSingle();
      if (!mounted) return;
      setState(() {
        _isFavorite = favResponse != null;
        if (statusResponse != null) {
          _currentStatus = statusResponse['status'] ?? 'Nenhum';
          _userStars = statusResponse['user_rating'] ?? 0;
        }
      });
    } catch (e) {
      debugPrint("Erro checar DB: $e");
    }
  }

  Future<void> _toggleFavorite() async {
    final user = _supabase.auth.currentUser;
    if (user == null || _gameDetails == null) return;
    final originalState = _isFavorite;
    setState(() => _isFavorite = !_isFavorite);
    try {
      if (!originalState) {
        await _supabase.from('favoritos').insert({
          'user_id': user.id, 'game_id': widget.gameId,
          'game_name': _gameDetails!['name'], 'game_image': _gameDetails!['background_image'],
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Adicionado aos Favoritos! 💜"), backgroundColor: _accentColor));
      } else {
        await _supabase.from('favoritos').delete().eq('user_id', user.id).eq('game_id', widget.gameId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFavorite = originalState);
    }
  }

  Future<void> _updateStatus(String status) async {
    final user = _supabase.auth.currentUser;
    if (user == null || _gameDetails == null) return;
    final originalStatus = _currentStatus;
    setState(() => _currentStatus = status);
    try {
      if (status == 'Nenhum') {
        await _supabase.from('biblioteca').delete().eq('user_id', user.id).eq('game_id', widget.gameId);
        setState(() => _userStars = 0);
      } else {
        await _supabase.from('biblioteca').upsert({
          'user_id': user.id, 
          'game_id': widget.gameId,
          'game_name': _gameDetails!['name'] ?? 'Sem nome', 
          'game_image': _gameDetails!['background_image'] ?? '', 
          'status': status, 
          'user_rating': _userStars > 0 ? _userStars : null
        }, onConflict: 'user_id, game_id');
        
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Salvo com sucesso! ✅"), backgroundColor: Color(0xFF00E054)));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _currentStatus = originalStatus);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _surfaceColor,
          title: const Text("Erro ao Salvar ❌", style: TextStyle(color: Colors.white)),
          content: Text("O banco de dados recusou: \n\n$e", style: const TextStyle(color: Colors.white70)),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK", style: TextStyle(color: _accentColor)))],
        )
      );
    }
  }

  Future<void> _updateStars(int stars) async {
    final user = _supabase.auth.currentUser;
    if (user == null || _gameDetails == null) return;
    if (_currentStatus == 'Nenhum') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Adicione o jogo a uma lista primeiro! 🎯"), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _userStars = stars);
    try {
      await _supabase.from('biblioteca').upsert({
        'user_id': user.id, 'game_id': widget.gameId,
        'game_name': _gameDetails!['name'], 'game_image': _gameDetails!['background_image'],
        'status': _currentStatus, 'user_rating': stars
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Avaliação salva! ⭐"), backgroundColor: Color(0xFF00E054)));
    } catch (e) {
      debugPrint("Erro estrelas: $e");
    }
  }

  // AQUI ESTÁ A FUNÇÃO QUE FALTAVA PARA LIMPAR A SINOPSE!
  String _cleanDescription(String? htmlDescription) {
    if (htmlDescription == null) return 'Sem descrição disponível.';
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlDescription.replaceAll(exp, '').trim();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: _accentColor)));
    if (_gameDetails == null) return const Scaffold(backgroundColor: Colors.black, body: Center(child: Text("Erro ao carregar", style: TextStyle(color: Colors.white))));

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(_gameDetails!['background_image'] ?? 'https://via.placeholder.com/400x600', width: double.infinity, height: 300, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: _surfaceColor, height: 300, child: const Center(child: Icon(Icons.broken_image, color: Colors.white24)))),
                Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black])))),
                Positioned(top: 40, left: 16, child: CircleAvatar(backgroundColor: Colors.black54, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)))),
                Positioned(top: 40, right: 16, child: CircleAvatar(backgroundColor: Colors.black54, child: IconButton(icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : Colors.white), onPressed: _toggleFavorite))),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_gameDetails!['name'] ?? '', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text("Lançamento: ${_gameDetails!['released'] ?? 'N/A'}", style: const TextStyle(color: Colors.white60)),
                  const SizedBox(height: 20),
                  
                  const Text("SUA AVALIAÇÃO", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.2)),
                  Row(
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(index < _userStars ? Icons.star : Icons.star_border),
                        color: _accentColor,
                        iconSize: 32,
                        onPressed: () => _updateStars(index + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  const Text("MEU STATUS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _currentStatus,
                    dropdownColor: _surfaceColor,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      fillColor: _surfaceColor,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Nenhum', child: Text('Adicionar à Lista...', style: TextStyle(color: Colors.white54))),
                      DropdownMenuItem(value: 'Já joguei', child: Text('✅ Já joguei')),
                      DropdownMenuItem(value: 'Pretendo jogar', child: Text('🎯 Pretendo jogar')),
                      DropdownMenuItem(value: 'Dropado', child: Text('❌ Dropado')),
                    ],
                    onChanged: (val) => _updateStatus(val ?? 'Nenhum'),
                  ),
                  const SizedBox(height: 24),
                  const Text("SINOPSE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text(_cleanDescription(_gameDetails!['description'] ?? _gameDetails!['description_raw']), style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.white70)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}