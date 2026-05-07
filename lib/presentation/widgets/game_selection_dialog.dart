import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/backlog_provider.dart';
import '../../domain/entities/game.dart';

class GameSelectionDialog extends StatefulWidget {
  final Function(Game game) onGameSelected;

  const GameSelectionDialog({super.key, required this.onGameSelected});

  @override
  State<GameSelectionDialog> createState() => _GameSelectionDialogState();
}

class _GameSelectionDialogState extends State<GameSelectionDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BacklogProvider>();
    final games = provider.gamesMap.values.where((game) {
      // Solo mostrar juegos que están en el backlog
      final isInBacklog = provider.backlogEntries.any((e) => e.gameId == game.id);
      if (!isInBacklog) return false;
      
      if (_searchQuery.isEmpty) return true;
      return game.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Seleccionar Juego',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar en tu biblioteca...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: games.isEmpty
                  ? const Center(
                      child: Text('No se encontraron juegos', style: TextStyle(color: Colors.white38)),
                    )
                  : ListView.builder(
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        final game = games[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: game.coverUrl != null
                                ? Image.network(
                                    game.coverUrl!,
                                    width: 40,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(color: Colors.grey[800], width: 40, height: 50),
                                  )
                                : Container(color: Colors.grey[800], width: 40, height: 50),
                          ),
                          title: Text(
                            game.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            game.platform ?? 'Sin plataforma',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onGameSelected(game);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
