import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/community_provider.dart';
import '../../../domain/entities/community_review.dart';
import '../../widgets/spoiler_text_widget.dart';
import '../../../core/theme/app_theme.dart';

class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Consumer<CommunityProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
          }

          if (provider.feed.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            color: AppColors.accentCyan,
            backgroundColor: AppColors.bgCard,
            onRefresh: () => provider.loadDiscoveryFeed(),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: provider.feed.length + (provider.hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                if (index == provider.feed.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: provider.isLoadingMore
                          ? const CircularProgressIndicator(color: AppColors.accentCyan)
                          : OutlinedButton.icon(
                              onPressed: () => provider.loadMoreDiscoveryFeed(),
                              icon: const Icon(Icons.expand_more_rounded),
                              label: const Text('Cargar más reseñas'),
                            ),
                    ),
                  );
                }
                final review = provider.feed[index];
                return _buildReviewCard(context, review, provider, index);
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
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentPurple.withOpacity(0.15),
                    AppColors.accentMagenta.withOpacity(0.15),
                  ],
                ),
              ),
              child: const Icon(Icons.people_alt_outlined, size: 48, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Text(
              'No hay actividad',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Aún no hay reseñas de otros usuarios en la comunidad.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, CommunityReview review, CommunityProvider provider, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 60)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF2A2A4A)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: User and Date
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.accentGradient,
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.transparent,
                      backgroundImage: review.userAvatarUrl != null
                          ? NetworkImage(review.userAvatarUrl!)
                          : null,
                      child: review.userAvatarUrl == null
                          ? Text(
                              review.username.substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.username,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary),
                        ),
                        Text(
                          _formatDate(review.addedDate),
                          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (review.rating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accentAmber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accentAmber.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.accentAmber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${review.rating}',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.accentAmber, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Content: Game and Review
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 56,
                      height: 78,
                      child: review.gameCoverUrl != null && review.gameCoverUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: review.gameCoverUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(color: AppColors.bgSurface),
                    ),
                  ),
                  const SizedBox(width: 14),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.gameTitle,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentCyan,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (review.reviewTitle != null && review.reviewTitle!.isNotEmpty)
                          Text(
                            review.reviewTitle!,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary),
                          ),
                        const SizedBox(height: 4),
                        if (review.isSpoiler) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accentAmber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_rounded, color: AppColors.accentAmber, size: 12),
                                const SizedBox(width: 4),
                                Text('SPOILER', style: TextStyle(color: AppColors.accentAmber, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          SpoilerTextWidget(text: review.notes),
                        ] else
                          Text(
                            review.notes,
                            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              Divider(color: const Color(0xFF2A2A4A), height: 1),
              const SizedBox(height: 10),
              
              // Footer: Like button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${review.likesCount}',
                    style: GoogleFonts.inter(
                      color: review.isLikedByMe ? AppColors.accentRose : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      review.isLikedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: review.isLikedByMe ? AppColors.accentRose : AppColors.textMuted,
                      size: 20,
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
