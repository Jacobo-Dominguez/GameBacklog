import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/backlog_provider.dart';

class UserReviewsScreen extends StatelessWidget {
  const UserReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final backlogProvider = context.watch<BacklogProvider>();
    final entries = backlogProvider.backlogEntries.where((e) {
      return (e.reviewTitle != null && e.reviewTitle!.isNotEmpty) || 
             (e.notes != null && e.notes!.isNotEmpty) ||
             (e.rating != null);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reseñas'),
      ),
      body: entries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no has escrito reseñas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final game = backlogProvider.gamesMap[entry.gameId];
                
                if (game == null) return const SizedBox.shrink();

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: game.coverUrl != null
                          ? Image.network(game.coverUrl!, width: 50, height: 75, fit: BoxFit.cover)
                          : Container(width: 50, height: 75, color: Colors.grey),
                    ),
                    title: Text(
                      game.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (entry.rating != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                Text(' ${entry.rating}/10'),
                              ],
                            ),
                          ),
                        if (entry.reviewTitle != null && entry.reviewTitle!.isNotEmpty)
                          Text(
                            entry.reviewTitle!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        if (entry.notes != null && entry.notes!.isNotEmpty)
                          Text(
                            entry.notes!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                    onTap: () => context.push('/game/${game.id}'),
                  ),
                );
              },
            ),
    );
  }
}
