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

  // Controla se a sinopse está expandida
  bool _descriptionExpanded = false;

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
      debugPrint('Erro: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUserRelations() async {
    final user = _supabase.auth.currentUser;
    if (user == null || _gameDetails == null) return;
    try {
      final favResponse = await _supabase
          .from('favoritos')
          .select()
          .eq('user_id', user.id)
          .eq('game_id', widget.gameId)
          .maybeSingle();
      final statusResponse = await _supabase
          .from('biblioteca')
          .select()
          .eq('user_id', user.id)
          .eq('game_id', widget.gameId)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _isFavorite = favResponse != null;
        if (statusResponse != null) {
          _currentStatus = statusResponse['status'] ?? 'Nenhum';
          _userStars = statusResponse['user_rating'] ?? 0;
        }
      });
    } catch (e) {
      debugPrint('Erro checar DB: $e');
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
          'user_id': user.id,
          'game_id': widget.gameId,
          'game_name': _gameDetails!['name'] ?? 'Sem nome',
          'game_image': _gameDetails!['background_image'] ?? '',
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Adicionado aos Favoritos! 💜'),
              backgroundColor: _accentColor));
        }
      } else {
        await _supabase
            .from('favoritos')
            .delete()
            .eq('user_id', user.id)
            .eq('game_id', widget.gameId);
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
        await _supabase
            .from('biblioteca')
            .delete()
            .eq('user_id', user.id)
            .eq('game_id', widget.gameId);
        setState(() => _userStars = 0);
      } else {
        await _supabase.from('biblioteca').upsert({
          'user_id': user.id,
          'game_id': widget.gameId,
          'game_name': _gameDetails!['name'] ?? 'Sem nome',
          'game_image': _gameDetails!['background_image'] ?? '',
          'status': status,
          'user_rating': _userStars > 0 ? _userStars : null,
        }, onConflict: 'user_id, game_id');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Salvo em: $status ✅'),
              backgroundColor: const Color(0xFF00E054)));
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _currentStatus = originalStatus);
    }
  }

  Future<void> _updateStars(int stars) async {
    final user = _supabase.auth.currentUser;
    if (user == null || _gameDetails == null) return;
    if (_currentStatus == 'Nenhum') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Adicione o jogo a uma lista primeiro! 🎯'),
          backgroundColor: Colors.orange));
      return;
    }
    setState(() => _userStars = stars);
    try {
      await _supabase.from('biblioteca').upsert({
        'user_id': user.id,
        'game_id': widget.gameId,
        'game_name': _gameDetails!['name'] ?? 'Sem nome',
        'game_image': _gameDetails!['background_image'] ?? '',
        'status': _currentStatus,
        'user_rating': stars,
      }, onConflict: 'user_id, game_id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Avaliação salva! ⭐'),
            backgroundColor: Color(0xFF00E054)));
      }
    } catch (e) {
      debugPrint('Erro estrelas: $e');
    }
  }

  // ─── Helpers de dados ────────────────────────────────────────────────────

  String _cleanDescription(String? html) {
    if (html == null || html.trim().isEmpty) return 'Sem descrição disponível.';
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  // Extrai lista de gêneros do JSON
  List<String> get _genres {
    final raw = _gameDetails?['genres'];
    if (raw == null || raw is! List) return [];
    return raw.map<String>((g) => g['name']?.toString() ?? '').toList();
  }

  // Extrai lista de plataformas do JSON
  List<String> get _platforms {
    final raw = _gameDetails?['platforms'];
    if (raw == null || raw is! List) return [];
    return raw
        .map<String>((p) => p['platform']?['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  }

  // Extrai desenvolvedoras
  List<String> get _developers {
    final raw = _gameDetails?['developers'];
    if (raw == null || raw is! List) return [];
    return raw.map<String>((d) => d['name']?.toString() ?? '').toList();
  }

  // Extrai publishers
  List<String> get _publishers {
    final raw = _gameDetails?['publishers'];
    if (raw == null || raw is! List) return [];
    return raw.map<String>((p) => p['name']?.toString() ?? '').toList();
  }

  // Nota Metacritic
  String get _metacritic {
    final score = _gameDetails?['metacritic'];
    if (score == null) return 'N/A';
    return score.toString();
  }

  // Cor do badge Metacritic
  Color _metacriticColor(String score) {
    final n = int.tryParse(score) ?? 0;
    if (n >= 75) return const Color(0xFF6CC644); // verde
    if (n >= 50) return const Color(0xFFFFAC33); // amarelo
    return const Color(0xFFE05252);              // vermelho
  }

  // ─── Widgets auxiliares ──────────────────────────────────────────────────

  // Label de seção (ex: "GÊNEROS")
  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white38,
              letterSpacing: 1.4),
        ),
      );

  // Chip genérico (gêneros, plataformas etc.)
  Widget _chip(String label, {Color? color}) => Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (color ?? Colors.white).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: (color ?? Colors.white).withOpacity(0.25), width: 1),
        ),
        child: Text(label,
            style: TextStyle(
                color: color ?? Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      );

  // Linha de informação (ex: "Desenvolvedora  Rockstar Games")
  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: Colors.white38, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, height: 1.4),
                children: [
                  TextSpan(
                      text: '$label  ',
                      style: const TextStyle(color: Colors.white38)),
                  TextSpan(
                      text: value,
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
        ]),
      );

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: _accentColor)));
    }
    if (_gameDetails == null) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
              child: Text('Erro ao carregar',
                  style: TextStyle(color: Colors.white))));
    }

    final description = _cleanDescription(
        _gameDetails!['description'] ?? _gameDetails!['description_raw']);
    final metacritic = _metacritic;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero image ────────────────────────────────────────────
            Stack(children: [
              Image.network(
                _gameDetails!['background_image'] ??
                    'https://via.placeholder.com/400x600',
                width: double.infinity,
                height: 280,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    color: _surfaceColor,
                    height: 280,
                    child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.white24))),
              ),
              // Gradiente inferior
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                      stops: [0.4, 1.0],
                    ),
                  ),
                ),
              ),
              // Botão voltar
              Positioned(
                top: 44,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              // Botão favoritar
              Positioned(
                top: 44,
                right: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ),
              ),
              // Badge Metacritic sobre a imagem (canto inferior direito)
              if (metacritic != 'N/A')
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('METACRITIC',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 9,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _metacriticColor(metacritic),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(metacritic,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20)),
                      ),
                    ],
                  ),
                ),
            ]),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Nome + data ──────────────────────────────────────
                  Text(_gameDetails!['name'] ?? '',
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(
                    'Lançamento: ${_gameDetails!['released'] ?? 'N/A'}',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),

                  const SizedBox(height: 20),

                  // ── Avaliação do usuário ─────────────────────────────
                  _sectionLabel('SUA AVALIAÇÃO'),
                  Row(
                    children: List.generate(5, (i) {
                      return IconButton(
                        icon: Icon(
                            i < _userStars ? Icons.star : Icons.star_border),
                        color: _accentColor,
                        iconSize: 30,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 36, minHeight: 36),
                        onPressed: () => _updateStars(i + 1),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  // ── Meu status ───────────────────────────────────────
                  _sectionLabel('MEU STATUS'),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: _currentStatus,
                    dropdownColor: _surfaceColor,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      fillColor: _surfaceColor,
                      filled: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Nenhum',
                          child: Text('Adicionar à Lista...',
                              style: TextStyle(color: Colors.white54))),
                      DropdownMenuItem(
                          value: 'Já joguei',
                          child: Text('✅ Já joguei')),
                      DropdownMenuItem(
                          value: 'Pretendo jogar',
                          child: Text('🎯 Pretendo jogar')),
                      DropdownMenuItem(
                          value: 'Dropado', child: Text('❌ Dropado')),
                    ],
                    onChanged: (val) => _updateStatus(val ?? 'Nenhum'),
                  ),

                  const SizedBox(height: 28),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 20),

                  // ── Informações gerais ───────────────────────────────
                  _sectionLabel('INFORMAÇÕES'),
                  const SizedBox(height: 4),

                  if (_developers.isNotEmpty)
                    _infoRow(Icons.code_outlined, 'Desenvolvedora',
                        _developers.join(', ')),

                  if (_publishers.isNotEmpty)
                    _infoRow(Icons.business_outlined, 'Publicadora',
                        _publishers.join(', ')),

                  _infoRow(
                    Icons.calendar_today_outlined,
                    'Lançamento',
                    _gameDetails!['released'] ?? 'N/A',
                  ),

                  if ((_gameDetails!['playtime'] ?? 0) > 0)
                    _infoRow(
                      Icons.timer_outlined,
                      'Tempo médio',
                      '${_gameDetails!['playtime']}h',
                    ),

                  if ((_gameDetails!['ratings_count'] ?? 0) > 0)
                    _infoRow(
                      Icons.people_outline,
                      'Avaliações',
                      '${_gameDetails!['ratings_count']} usuários',
                    ),

                  const SizedBox(height: 16),

                  // ── Gêneros ──────────────────────────────────────────
                  if (_genres.isNotEmpty) ...[
                    _sectionLabel('GÊNEROS'),
                    Wrap(
                      children: _genres
                          .map((g) => _chip(g, color: _accentColor))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // ── Plataformas ──────────────────────────────────────
                  if (_platforms.isNotEmpty) ...[
                    _sectionLabel('PLATAFORMAS'),
                    Wrap(
                      children: _platforms.map((p) => _chip(p)).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],

                  const SizedBox(height: 8),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 20),

                  // ── Sinopse ──────────────────────────────────────────
                  _sectionLabel('SINOPSE'),
                  const SizedBox(height: 4),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    crossFadeState: _descriptionExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: Text(
                      description,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, height: 1.6, color: Colors.white70),
                    ),
                    secondChild: Text(
                      description,
                      style: const TextStyle(
                          fontSize: 14, height: 1.6, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => setState(
                        () => _descriptionExpanded = !_descriptionExpanded),
                    child: Text(
                      _descriptionExpanded ? 'Ver menos ▲' : 'Ver mais ▼',
                      style: TextStyle(
                          color: _accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
