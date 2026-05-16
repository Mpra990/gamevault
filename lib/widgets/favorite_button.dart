import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteButton extends StatefulWidget {
  final int gameId;
  final String gameName;
  final String? gameImage;

  const FavoriteButton({
    super.key,
    required this.gameId,
    required this.gameName,
    this.gameImage,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isFavorite = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _supabase
          .from('favoritos')
          .select()
          .eq('user_id', user.id)
          .eq('game_id', widget.gameId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isFavorite = response != null;
        });
      }
    } catch (e) {
      debugPrint('Erro ao checar favorito: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    final user = _supabase.auth.currentUser;
    if (user == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      if (_isFavorite) {
        await _supabase
            .from('favoritos')
            .delete()
            .eq('user_id', user.id)
            .eq('game_id', widget.gameId);
        
        if (!mounted) return;
        setState(() {
          _isFavorite = false;
        });
      } else {
        await _supabase.from('favoritos').insert({
          'user_id': user.id,
          'game_id': widget.gameId,
          'game_name': widget.gameName,
          'game_image': widget.gameImage,
        });

        if (!mounted) return;
        setState(() {
          _isFavorite = true;
        });
      }
    } catch (e) {
      debugPrint('Erro ao alternar favorito: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isFavorite ? Icons.favorite : Icons.favorite_border,
        color: _isFavorite ? Colors.red : Colors.white,
        size: 28,
      ),
      onPressed: _isProcessing ? null : _toggleFavorite,
    );
  }
}