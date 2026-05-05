import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/community_provider.dart';
import '../../../domain/entities/community_review.dart';
import '../../widgets/spoiler_text_widget.dart';

class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<CommunityProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.feed.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadDiscoveryFeed(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.feed.length + (provider.hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                if (index == provider.feed.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: provider.isLoadingMore
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: () => provider.loadMoreDiscoveryFeed(),
                              child: const Text('Cargar más reseñas'),
                            ),
                    ),
                  );
                }
                final review = provider.feed[index];
                return _buildReviewCard(context, review, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_alt_outlined, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 20),
            Text(
              'No hay actividad',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Aún no hay reseñas de otros usuarios en la comunidad.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, CommunityReview review, CommunityProvider provider) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Si queremos, podemos ir al detalle del juego
          // context.push('/game/${review.gameId}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera: Usuario y Fecha
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: review.userAvatarUrl != null
                        ? NetworkImage(review.userAvatarUrl!)
                        : null,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: review.userAvatarUrl == null
                        ? Text(review.username.substring(0, 1).toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.username,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          _formatDate(review.addedDate),
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (review.rating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${review.rating}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Contenido: Juego y Reseña
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Portada del juego
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 60,
                      height: 85,
                      child: review.gameCoverUrl != null && review.gameCoverUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: review.gameCoverUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(color: Colors.grey[800]),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Texto de la reseña
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.gameTitle,
                          style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 4),
                        if (review.reviewTitle != null && review.reviewTitle!.isNotEmpty)
                          Text(
                            review.reviewTitle!,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        const SizedBox(height: 4),
                        if (review.isSpoiler) ...[
                          const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange, size: 14),
                              SizedBox(width: 4),
                              Text('SPOILER', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SpoilerTextWidget(text: review.notes),
                        ] else
                          Text(review.notes),
                      ],
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 24),
              
              // Footer: Botón Like
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${review.likesCount}',
                    style: TextStyle(
                      color: review.isLikedByMe ? Colors.red : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      review.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                      color: review.isLikedByMe ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => provider.toggleLike(review.reviewId),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Hace ${difference.inMinutes} minutos';
      }
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
