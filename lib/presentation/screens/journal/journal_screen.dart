import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/backlog_provider.dart';
import '../../../domain/entities/game_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/session_dialog.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Consumer<BacklogProvider>(
        builder: (context, provider, child) {
          final sessions = provider.getSessionsForDay(_selectedDay ?? _focusedDay);

          return Row(
            children: [
              // Panel Izquierdo: Calendario y Estadísticas
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCalendarCard(provider),
                      const SizedBox(height: 24),
                      _buildSummaryStats(provider),
                    ],
                  ),
                ),
              ),
              // Panel Derecho: Sesiones del Día Seleccionado
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgCard.withOpacity(0.5),
                    border: const Border(left: BorderSide(color: Color(0xFF2A2A4A))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Text(
                              'Sesiones del ${_formatSelectedDate()}',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            if (sessions.isNotEmpty)
                              _buildSessionCountBadge(sessions.length),
                          ],
                        ),
                      ),
                      Expanded(
                        child: sessions.isEmpty
                            ? _buildEmptySessions()
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                itemCount: sessions.length,
                                itemBuilder: (context, index) => _buildSessionItem(sessions[index], provider, index),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildAddSessionFAB(context),
    );
  }

  Widget _buildAddSessionFAB(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.accentCyan.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _showAddSessionDialog(context),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.bgDark,
        elevation: 0,
        icon: const Icon(Icons.add_task_rounded),
        label: Text('Registrar Sesión', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddSessionDialog(BuildContext context) {
    // Al no pasar gameId, el diálogo debería permitir seleccionar un juego
    showDialog(
      context: context,
      builder: (context) => const SessionDialog(),
    );
  }

  Widget _buildCalendarCard(BacklogProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A4A)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.now(),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        calendarStyle: CalendarStyle(
          defaultTextStyle: const TextStyle(color: AppColors.textSecondary),
          weekendTextStyle: const TextStyle(color: AppColors.accentRose),
          todayDecoration: BoxDecoration(color: AppColors.accentCyan.withOpacity(0.15), shape: BoxShape.circle),
          selectedDecoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
          markerDecoration: const BoxDecoration(color: AppColors.accentTeal, shape: BoxShape.circle),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.accentCyan),
          rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.accentCyan),
        ),
        eventLoader: (day) => provider.getSessionsForDay(day),
      ),
    );
  }

  Widget _buildSummaryStats(BacklogProvider provider) {
    final totalMinutes = provider.getTotalMinutesPlayed();
    final totalHours = (totalMinutes / 60).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.accentCyan.withOpacity(0.1), AppColors.accentPurple.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentCyan.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen de Actividad', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          _buildMiniStat(Icons.timer_outlined, 'Tiempo total', '${totalHours}h', AppColors.accentCyan),
          const SizedBox(height: 12),
          _buildMiniStat(Icons.history_rounded, 'Sesiones', '${provider.recentSessions.length}', AppColors.accentPurple),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildSessionCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.accentTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text('$count sesiones', style: GoogleFonts.inter(color: AppColors.accentTeal, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptySessions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 64, color: AppColors.textMuted.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('Sin actividad registrada para hoy', style: GoogleFonts.inter(color: AppColors.textMuted)),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => _showAddSessionDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Registrar ahora'),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentCyan),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionItem(GameSession session, BacklogProvider provider, int index) {
    final game = provider.gamesMap[session.gameId];
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(20 * (1 - value), 0), child: child)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2A2A4A))),
        child: Row(
          children: [
            Column(children: [
              Text('${session.durationMinutes}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
              Text('min', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
            ]),
            const SizedBox(width: 20),
            Container(width: 1, height: 40, color: const Color(0xFF2A2A4A)),
            const SizedBox(width: 20),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(game?.title ?? 'Juego desconocido', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              if (session.description != null && session.description!.isNotEmpty)
                Text(session.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
            ])),
            IconButton(icon: const Icon(Icons.edit_note_rounded, color: AppColors.textMuted), onPressed: () {}),
          ],
        ),
      ),
    );
  }

  String _formatSelectedDate() {
    if (_selectedDay == null) return 'hoy';
    final now = DateTime.now();
    if (isSameDay(_selectedDay, now)) return 'hoy';
    return '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}';
  }
}
