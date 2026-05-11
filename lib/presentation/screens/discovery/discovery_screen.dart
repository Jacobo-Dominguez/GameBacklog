import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../providers/community_provider.dart';
import '../../../domain/entities/game.dart';
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
            child: MasonryGridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              itemCount: provider.feed.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.feed.length) {
                  return _buildLoadMoreButton(provider);
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

  Widget _buildLoadMoreButton(CommunityProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: provider.isLoadingMore
            ? const CircularProgressIndicator(color: AppColors.accentCyan)
            : OutlinedButton(
                onPressed: () => provider.loadMoreDiscoveryFeed(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2A2A4A)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cargar más'),
              ),
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A4A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User and Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.accentCyan.withOpacity(0.2),
                        backgroundImage: review.userAvatarUrl != null
                            ? NetworkImage(review.userAvatarUrl!)
                            : null,
                        child: review.userAvatarUrl == null
                            ? Text(
                                review.username.substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 10),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          review.username,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (review.rating != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.accentAmber, size: 14),
                            Text(
                              '${review.rating}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.accentAmber, fontSize: 12),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  InkWell(
                    onTap: () {
                      final game = Game(
                        id: review.gameId,
                        title: review.gameTitle,
                        coverUrl: review.gameCoverUrl,
                        remoteId: int.tryParse(review.gameId.replaceAll('igdb_', '')),
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                        userId: review.userId, // Usamos el ID del autor como placeholder
                      );
                      context.push('/game/${review.gameId}', extra: game);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 30,
                            height: 40,
                            child: review.gameCoverUrl != null && review.gameCoverUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: review.gameCoverUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : Container(color: AppColors.bgSurface),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            review.gameTitle,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentCyan,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (review.reviewTitle != null && review.reviewTitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        review.reviewTitle!,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Review content with "Read more"
                  _ExpandableText(
                    text: review.notes,
                    isSpoiler: review.isSpoiler,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            
            // Footer: Like button and Date
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF2A2A4A))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(review.addedDate),
                    style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10),
                  ),
                  Row(
                    children: [
                      Text(
                        '${review.likesCount}',
                        style: GoogleFonts.inter(
                          color: review.isLikedByMe ? AppColors.accentRose : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 2),
                      GestureDetector(
                        onTap: () => provider.toggleLike(review.reviewId),
                        child: Icon(
                          review.isLikedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: review.isLikedByMe ? AppColors.accentRose : AppColors.textMuted,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m';
      }
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}

class _ExpandableText extends StatefulWidget {
  final String text;
  final bool isSpoiler;
  final int maxLines;

  const _ExpandableText({
    required this.text,
    required this.isSpoiler,
    required this.maxLines,
  });

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isSpoiler && !_isExpanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accentAmber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.warning_rounded, color: AppColors.accentAmber, size: 10),
                SizedBox(width: 4),
                Text('SPOILER', style: TextStyle(color: AppColors.accentAmber, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SpoilerTextWidget(text: widget.text),
          TextButton(
            onPressed: () => setState(() => _isExpanded = true),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Leer reseña', style: TextStyle(color: AppColors.accentCyan, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(
          text: widget.text,
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
        );
        final tp = TextPainter(
          text: span,
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        );
        tp.layout(maxWidth: constraints.maxWidth);

        if (tp.didExceedMaxLines) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.text,
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                maxLines: _isExpanded ? null : widget.maxLines,
                overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _isExpanded ? 'Leer menos' : 'Leer más',
                    style: const TextStyle(
                      color: AppColors.accentCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          return Text(
            widget.text,
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          );
        }
      },
    );
  }
}
