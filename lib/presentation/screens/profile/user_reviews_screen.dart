import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:game_backlog/presentation/providers/backlog_provider.dart';
import 'package:game_backlog/domain/entities/user_review.dart';
import 'package:game_backlog/core/theme/app_theme.dart';

class UserReviewsScreen extends StatefulWidget {
  const UserReviewsScreen({super.key});

  @override
  State<UserReviewsScreen> createState() => _UserReviewsScreenState();
}

class _UserReviewsScreenState extends State<UserReviewsScreen> {
  late Future<List<UserReview>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _loadReviews() {
    _reviewsFuture = context.read<BacklogProvider>().getAllUserReviews();
  }

  @override
  Widget build(BuildContext context) {
    final backlogProvider = context.watch<BacklogProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text('Mis Reseñas', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<UserReview>>(
        future: _reviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }

          final reviews = snapshot.data ?? [];
          
          if (reviews.isEmpty) {
            return _buildEmptyState();
          }

          // Agrupar reseñas por gameId
          final groupedReviews = <String, List<UserReview>>{};
          for (final review in reviews) {
            groupedReviews.putIfAbsent(review.gameId, () => []).add(review);
          }

          final gameIds = groupedReviews.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: gameIds.length,
            itemBuilder: (context, index) {
              final gameId = gameIds[index];
              final gameReviews = groupedReviews[gameId]!;
              final game = backlogProvider.gamesMap[gameId];

              if (game == null) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabecera del Juego
                    InkWell(
                      onTap: () => context.push('/game/$gameId'),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 60,
                              height: 80,
                              child: game.coverUrl != null
                                  ? Image.network(game.coverUrl!, fit: BoxFit.cover)
                                  : Container(color: AppColors.bgElevated, child: const Icon(Icons.videogame_asset)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  game.title,
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${gameReviews.length} ${gameReviews.length == 1 ? 'reseña' : 'reseñas'}',
                                  style: GoogleFonts.inter(color: AppColors.accentCyan, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Lista de Reseñas para este juego
                    ...gameReviews.map((review) => _buildReviewCard(review)).toList(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(UserReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (review.title != null && review.title!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                review.title!,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
              ),
            ),
          if (review.isSpoiler)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.accentRose.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: const Text('SPOILER', style: TextStyle(color: AppColors.accentRose, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          Text(
            review.content ?? '',
            style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Escrito el ${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 80, color: AppColors.textMuted.withOpacity(0.2)),
          const SizedBox(height: 24),
          Text(
            'Aún no has escrito ninguna reseña',
            style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Text(
            'Tus opiniones aparecerán aquí',
            style: GoogleFonts.inter(color: AppColors.textMuted.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}
