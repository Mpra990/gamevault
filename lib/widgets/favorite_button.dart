import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteButton extends StatefulWidget {
  final int gameId;
  final String name;
  final String image;

  const FavoriteButton({
    super.key,
    required this.gameId,
    required this.name,
    required this.image,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool isFavorite = false;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  // Verifica se o jogo já está nos favoritos ao carregar a tela
  Future<void> _checkIfFavorite() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('favoritos')
          .select()
          .eq('user_id', user.id)
          .eq('game_id', widget.gameId)
          .maybeSingle();

      if (mounted && data != null) {
        setState(() => isFavorite = true);
      }
    } catch (e) {
      debugPrint("Erro ao verificar favorito: $e");
    }
  }

  Future<void> _toggleFavorite() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Faça login para favoritar!")),
      );
      return;
    }

    try {
      if (isFavorite) {
        // Remover dos favoritos
        await supabase
            .from('favoritos')
            .delete()
            .eq('user_id', user.id)
            .eq('game_id', widget.gameId);
      } else {
        // Adicionar aos favoritos
        await supabase.from('favoritos').insert({
          'user_id': user.id,
          'game_id': widget.gameId,
          'game_name': widget.name,
          'game_image': widget.image,
        });
      }

      setState(() => isFavorite = !isFavorite);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao salvar: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.red : Colors.white,
      ),
      onPressed: _toggleFavorite,
    );
  }
}
