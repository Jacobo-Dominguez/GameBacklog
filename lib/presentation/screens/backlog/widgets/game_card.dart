import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../domain/entities/game.dart';
import '../../../../../domain/entities/game_backlog_entry.dart';
import '../../../../../core/theme/app_theme.dart';

class GameCard extends StatefulWidget {
  final GameBacklogEntry entry;
  final Game game;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showMenu;

  const GameCard({
    super.key,
    required this.entry,
    required this.game,
    required this.onEdit,
    required this.onDelete,
    this.showMenu = true,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'playing': return AppColors.statusPlaying;
      case 'completed': return AppColors.statusCompleted;
      case 'dropped': return AppColors.statusDropped;
      case 'on_hold': return AppColors.statusOnHold;
      default: return AppColors.statusPending;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'playing': return 'Jugando';
      case 'completed': return 'Completado';
      case 'dropped': return 'Abandonado';
      case 'on_hold': return 'En pausa';
      default: return 'Pendiente';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'playing': return Icons.play_arrow_rounded;
      case 'completed': return Icons.check_circle_rounded;
      case 'dropped': return Icons.cancel_rounded;
      case 'on_hold': return Icons.pause_circle_rounded;
      default: return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.entry.status);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.15 * _glowAnimation.value),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: AppColors.bgCard,
                  child: InkWell(
                    onTap: () => context.push('/game/${widget.game.id}', extra: widget.game),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cover Image with overlay
                        Stack(
                          children: [
                            SizedBox(
                              height: 140,
                              width: double.infinity,
                              child: widget.game.coverUrl != null && widget.game.coverUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: widget.game.coverUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: AppColors.bgSurface,
                                        child: Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: statusColor.withOpacity(0.5),
                                            ),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: AppColors.bgSurface,
                                        child: Icon(Icons.broken_image_rounded, size: 36, color: AppColors.textMuted),
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            statusColor.withOpacity(0.2),
                                            AppColors.bgSurface,
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.videogame_asset_rounded,
                                          size: 48,
                                          color: statusColor.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                            ),

                            // Gradient overlay bottom
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      AppColors.bgCard.withOpacity(0.9),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Status badge
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: statusColor.withOpacity(0.4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getStatusIcon(widget.entry.status),
                                      size: 12,
                                      color: AppColors.bgDark,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getStatusLabel(widget.entry.status),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.bgDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Menu
                            if (widget.showMenu)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') widget.onEdit();
                                    if (value == 'delete') widget.onDelete();
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_rounded, size: 18, color: AppColors.accentCyan),
                                          SizedBox(width: 10),
                                          Text('Editar'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_rounded, color: AppColors.accentRose, size: 18),
                                          SizedBox(width: 10),
                                          Text('Eliminar', style: TextStyle(color: AppColors.accentRose)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  icon: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.white70),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Content
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                widget.game.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              if (widget.game.platform != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.game.platform!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],

                              const SizedBox(height: 10),

                              // Stats row
                              Row(
                                children: [
                                  if (widget.entry.hoursPlayed > 0) ...[
                                    _buildStatChip(
                                      Icons.access_time_rounded,
                                      '${widget.entry.hoursPlayed}h',
                                      AppColors.accentCyan,
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  if (widget.entry.rating != null)
                                    _buildStatChip(
                                      Icons.star_rounded,
                                      widget.entry.rating.toString(),
                                      AppColors.accentAmber,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
