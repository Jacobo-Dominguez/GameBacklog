import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/backlog_provider.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/game.dart';
import '../../core/theme/app_theme.dart';

class SessionDialog extends StatefulWidget {
  final String? gameId;
  final GameSession? existingSession;
  final DateTime? initialDate;

  const SessionDialog({
    super.key,
    this.gameId,
    this.existingSession,
    this.initialDate,
  });

  @override
  State<SessionDialog> createState() => _SessionDialogState();
}

class _SessionDialogState extends State<SessionDialog> {
  late TextEditingController _hoursController;
  late TextEditingController _minsController;
  late TextEditingController _descController;
  late DateTime _selectedDate;
  String? _selectedGameId;

  @override
  void initState() {
    super.initState();
    final hours = widget.existingSession != null ? (widget.existingSession!.durationMinutes / 60).floor() : 0;
    final mins = widget.existingSession != null ? widget.existingSession!.durationMinutes % 60 : 0;
    
    _hoursController = TextEditingController(text: hours > 0 ? hours.toString() : '');
    _minsController = TextEditingController(text: mins > 0 ? mins.toString() : '');
    _descController = TextEditingController(text: widget.existingSession?.description ?? '');
    _selectedDate = widget.existingSession?.sessionDate ?? widget.initialDate ?? DateTime.now();
    _selectedGameId = widget.gameId ?? widget.existingSession?.gameId;
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minsController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BacklogProvider>(
      builder: (context, provider, _) {
        final allGames = provider.gamesMap.values.toList();

        return AlertDialog(
          backgroundColor: AppColors.bgElevated,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
          title: Text(
            widget.existingSession == null ? 'Registrar Sesión' : 'Editar Sesión',
            style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.gameId == null && widget.existingSession == null) ...[
                  Text('Juego', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGameId,
                        dropdownColor: AppColors.bgElevated,
                        hint: const Text('Selecciona un juego', style: TextStyle(color: AppColors.textMuted)),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.accentCyan),
                        items: allGames.map((game) => DropdownMenuItem(
                          value: game.id,
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  width: 24,
                                  height: 32,
                                  child: game.coverUrl != null
                                      ? CachedNetworkImage(imageUrl: game.coverUrl!, fit: BoxFit.cover, placeholder: (context, url) => Container(color: Colors.white10))
                                      : Container(color: Colors.white10, child: const Icon(Icons.videogame_asset, size: 12)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(game.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedGameId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                
                Text('Fecha de la sesión', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: AppColors.accentCyan, size: 18),
                        const SizedBox(width: 12),
                        Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                Text('Duración', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildTimeField(_hoursController, 'Horas')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTimeField(_minsController, 'Minutos')),
                  ],
                ),
                const SizedBox(height: 20),
                
                Text('Notas (opcional)', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '¿Qué hiciste hoy?',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.bgCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted))),
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: AppColors.primaryGradient),
              child: ElevatedButton(
                onPressed: () => _saveSession(provider),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: AppColors.bgDark, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.accentCyan, onPrimary: AppColors.bgDark, surface: AppColors.bgElevated, onSurface: AppColors.textPrimary)), child: child!),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveSession(BacklogProvider provider) async {
    if (_selectedGameId == null) return;
    
    final h = int.tryParse(_hoursController.text) ?? 0;
    final m = int.tryParse(_minsController.text) ?? 0;
    final totalMinutes = (h * 60) + m;

    if (totalMinutes > 0) {
      bool success;
      if (widget.existingSession == null) {
        success = await provider.addGameSession(
          gameId: _selectedGameId!,
          date: _selectedDate,
          durationMinutes: totalMinutes,
          description: _descController.text,
        );
      } else {
        success = await provider.updateGameSession(
          sessionId: widget.existingSession!.id,
          date: _selectedDate,
          durationMinutes: totalMinutes,
          description: _descController.text,
        );
      }

      if (success && mounted) Navigator.pop(context, true);
    }
  }
}
