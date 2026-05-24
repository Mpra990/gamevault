import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _supabase = Supabase.instance.client;
  final _nameController = TextEditingController();
  final _avatarController = TextEditingController();
  
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final Color _accentColor = const Color(0xFF00E5FF);
  final Color _surfaceColor = const Color(0xFF1A1D21);

  @override
  void initState() {
    super.initState();
    _loadUserProfileAndFavorites();
  }

  Future<void> _loadUserProfileAndFavorites() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final profileData = await _supabase.from('profiles').select().eq('id', user.id).maybeSingle();
      final favsData = await _supabase.from('favoritos').select().eq('user_id', user.id).order('created_at', ascending: true);

      if (profileData != null) {
        setState(() {
          _nameController.text = profileData['username'] ?? '';
          _avatarController.text = profileData['avatar_url'] ?? '';
        });
      }
      setState(() {
        _favorites = List<Map<String, dynamic>>.from(favsData);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar configurações: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(int favId) async {
    try {
      await _supabase.from('favoritos').delete().eq('id', favId);
      setState(() {
        _favorites.removeWhere((item) => item['id'] == favId);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jogo removido dos favoritos!")));
    } catch (e) {
      debugPrint("Erro ao remover: $e");
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'username': _nameController.text.trim(),
        'avatar_url': _avatarController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Perfil updated!"), backgroundColor: Color(0xFF00E054)));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("CONFIGURAÇÕES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("NOME DE USUÁRIO", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white60, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController, 
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Digite seu novo nome",
                      hintStyle: const TextStyle(color: Colors.white24),
                      fillColor: _surfaceColor,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  const Text("URL DA FOTO DE PERFIL", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white60, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _avatarController, 
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Cole o link de uma imagem",
                      hintStyle: const TextStyle(color: Colors.white24),
                      fillColor: _surfaceColor,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text("EDITAR TOP FAVORITOS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white60, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  _favorites.isEmpty
                      ? const Text("Nenhum favorito para remover.", style: TextStyle(color: Colors.white38, fontSize: 14))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _favorites.length,
                          itemBuilder: (context, index) {
                            final item = _favorites[index];
                            return Card(
                              color: _surfaceColor,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(item['game_image'] ?? '', width: 40, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.gamepad, color: Colors.white24)),
                                ),
                                title: Text(item['game_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white), maxLines: 1),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () => _removeFavorite(item['id']),
                                ),
                              ),
                            );
                          },
                        ),

                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : _saveSettings,
                      child: _isSaving ? const CircularProgressIndicator(color: Colors.black) : const Text("SALVAR ALTERAÇÕES", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent, 
                        side: const BorderSide(color: Colors.redAccent, width: 1.5), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _signOut, child: const Text("SAIR DA CONTA", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}