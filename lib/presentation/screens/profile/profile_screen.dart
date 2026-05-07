import 'package:flutter/material.dart';
import '../../../core/utils/image_utils.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/backlog_provider.dart';
import '../../../data/datasources/game_backlog_local_datasource_impl.dart';
import '../../../data/datasources/database_helper.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, int> _stats = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final auth = context.read<AuthProvider>();
    if (auth.currentUser == null) return;
    try {
      final ds = GameBacklogLocalDataSourceImpl(DatabaseHelper.instance);
      final s = await ds.getStatsByUserId(auth.currentUser!.id);
      if (mounted) setState(() { _stats = s; _isLoadingStats = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bp = context.watch<BacklogProvider>();
    final user = auth.currentUser;
    if (user == null) return const Scaffold(backgroundColor: AppColors.bgDark, body: Center(child: CircularProgressIndicator(color: AppColors.accentCyan)));

    final favs = bp.backlogEntries.where((e) => e.isFavorite).toList();
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(children: [
            _buildHeader(context, user),
            const SizedBox(height: 32),
            if (favs.isNotEmpty) ...[_buildFavs(context, favs, bp.gamesMap), const SizedBox(height: 32)],
            _buildStatsCard(context, bp),
            const SizedBox(height: 32),
            _buildActions(context, auth),
            const SizedBox(height: 32),
          ]),
        )),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user) {
    final img = ImageUtils.getAvatarProvider(user.avatarUrl);
    return Column(children: [
      GestureDetector(
        onTap: () => context.push('/edit-profile'),
        child: Stack(children: [
          Container(
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient,
              boxShadow: [BoxShadow(color: AppColors.accentCyan.withOpacity(0.3), blurRadius: 24, spreadRadius: 2)]),
            padding: const EdgeInsets.all(3),
            child: CircleAvatar(radius: 58, backgroundColor: AppColors.bgDark, backgroundImage: img,
              child: img == null ? Text(user.username[0].toUpperCase(), style: GoogleFonts.outfit(fontSize: 42, color: AppColors.accentCyan, fontWeight: FontWeight.bold)) : null),
          ),
          Positioned(bottom: 2, right: 2, child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(gradient: AppColors.accentGradient, shape: BoxShape.circle, border: Border.all(color: AppColors.bgDark, width: 3)),
            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
          )),
        ]),
      ),
      const SizedBox(height: 18),
      Text(user.username, style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 4),
      Text(user.email, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
      const SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: AppColors.primaryGradient,
          boxShadow: [BoxShadow(color: AppColors.accentCyan.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))]),
        child: FilledButton.icon(onPressed: () => context.push('/edit-profile'),
          icon: const Icon(Icons.settings_rounded, size: 18), label: Text('Editar Perfil', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          style: FilledButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: AppColors.bgDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      ),
      const SizedBox(height: 10),
      Text('Miembro desde ${_fmtDate(user.createdAt)}', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
    ]);
  }

  Widget _buildFavs(BuildContext context, List<dynamic> favs, Map<String, dynamic> gamesMap) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Row(children: [
        const Icon(Icons.favorite_rounded, color: AppColors.accentRose, size: 22), const SizedBox(width: 10),
        Text('Juegos Favoritos', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ])),
      const SizedBox(height: 16),
      SizedBox(height: 200, child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, itemCount: favs.length,
        itemBuilder: (ctx, i) {
          final game = gamesMap[favs[i].gameId];
          if (game == null) return const SizedBox.shrink();
          return GestureDetector(onTap: () => context.go('/game/${game.id}'), child: Container(width: 120, margin: const EdgeInsets.symmetric(horizontal: 6), child: Column(children: [
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(14),
              child: game.coverUrl != null && game.coverUrl.isNotEmpty
                ? Image.network(game.coverUrl!, fit: BoxFit.cover, width: double.infinity)
                : Container(color: AppColors.bgSurface, child: const Icon(Icons.videogame_asset_rounded, color: AppColors.textMuted)))),
            const SizedBox(height: 8),
            Text(game.title, maxLines: 2, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
          ])));
        },
      )),
    ]);
  }

  Widget _buildStatsCard(BuildContext context, BacklogProvider p) {
    final stats = p.stats; final total = p.getTotalGames();
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF2A2A4A))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Tu Backlog en cifras', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 20),
        if (total == 0) Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('No hay juegos añadidos aún.', style: GoogleFonts.inter(color: AppColors.textMuted))))
        else Column(children: [
          _statRow('Jugando', stats['playing'] ?? 0, AppColors.statusPlaying, Icons.play_arrow_rounded),
          const Divider(color: Color(0xFF2A2A4A), height: 24),
          _statRow('Completados', stats['completed'] ?? 0, AppColors.statusCompleted, Icons.check_circle_rounded),
          const Divider(color: Color(0xFF2A2A4A), height: 24),
          _statRow('Pendientes', stats['pending'] ?? 0, AppColors.statusPending, Icons.schedule_rounded),
          const Divider(color: Color(0xFF2A2A4A), height: 24),
          _statRow('En pausa', stats['on_hold'] ?? 0, AppColors.statusOnHold, Icons.pause_circle_rounded),
          const Divider(color: Color(0xFF2A2A4A), height: 24),
          _statRow('Abandonados', stats['dropped'] ?? 0, AppColors.statusDropped, Icons.cancel_rounded),
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.accentCyan.withOpacity(0.1), AppColors.accentPurple.withOpacity(0.1)]),
            borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.accentCyan.withOpacity(0.15))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Total', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ShaderMask(shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                child: Text('$total', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white))),
            ])),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
            color: AppColors.accentCyan.withOpacity(0.05), borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Tiempo Total', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text('${p.getTotalMinutesPlayed()} min', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.accentCyan)),
            ])),
        ]),
      ]),
    ));
  }

  Widget _statRow(String label, int count, Color color, IconData icon) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 16)),
      const SizedBox(width: 14),
      Text(label, style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary)),
      const Spacer(),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
        child: Text('$count', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: color))),
    ]));
  }

  Widget _buildActions(BuildContext context, AuthProvider auth) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(children: [
      _actionBtn(Icons.rate_review_outlined, 'Mis Reseñas', () => context.push('/user-reviews'), AppColors.accentPurple),
      const SizedBox(height: 10),
      _actionBtn(Icons.calendar_month_outlined, 'Mi Diario', () => context.push('/journal'), AppColors.accentTeal),
      const SizedBox(height: 10),
      _actionBtn(Icons.collections_bookmark_outlined, 'Colecciones', () => context.push('/collections'), AppColors.accentCyan),
      const SizedBox(height: 10),
      _actionBtn(Icons.explore_outlined, 'Comunidad', () => context.push('/discovery'), AppColors.accentMagenta),
      const SizedBox(height: 10),
      _actionBtn(Icons.bug_report_outlined, 'Dev Tools', () => context.push('/api-test'), AppColors.accentAmber),
      const SizedBox(height: 16),
      Container(width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.accentRose.withOpacity(0.3))),
        child: ElevatedButton.icon(onPressed: () => _logout(context, auth),
          icon: const Icon(Icons.logout_rounded), label: Text('Cerrar Sesión', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRose.withOpacity(0.1), foregroundColor: AppColors.accentRose,
            shadowColor: Colors.transparent, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
    ]));
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap, Color color) {
    return Container(
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF2A2A4A))),
      child: Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14), child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 16),
          Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 22),
        ])))));
  }

  Future<void> _logout(BuildContext context, AuthProvider auth) async {
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('¿Cerrar sesión?'), content: const Text('Tu backlog se mantendrá guardado localmente.'),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sí, salir'))]));
    if (ok == true && context.mounted) { await auth.logout(); if (context.mounted) context.go('/login'); }
  }

  String _fmtDate(DateTime d) {
    final m = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
    return '${d.day} de ${m[d.month - 1]} de ${d.year}';
  }
}