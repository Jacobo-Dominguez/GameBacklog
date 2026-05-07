import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/backlog_provider.dart';
import '../../../domain/entities/game_list.dart';
import '../../../core/theme/app_theme.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});
  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Consumer<BacklogProvider>(
        builder: (context, provider, _) {
          final lists = provider.gameLists;
          if (lists.isEmpty) return _buildEmptyState(context);
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: lists.length,
            itemBuilder: (context, index) => _buildListCard(context, lists[index], provider, index),
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppColors.primaryGradient,
          boxShadow: [BoxShadow(color: AppColors.accentCyan.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showCreateListDialog(context),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.bgDark,
          elevation: 0,
          icon: const Icon(Icons.add_rounded),
          label: Text('Nueva Lista', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: LinearGradient(colors: [AppColors.accentPurple.withOpacity(0.12), AppColors.accentCyan.withOpacity(0.12)])),
          child: const Icon(Icons.collections_bookmark_outlined, size: 48, color: AppColors.textMuted)),
        const SizedBox(height: 24),
        Text('Sin colecciones', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Text('Crea listas personalizadas para organizar tus juegos.\nPor ejemplo: "RPGs favoritos", "Para jugar en verano"...',
          textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14, height: 1.5)),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: AppColors.primaryGradient,
            boxShadow: [BoxShadow(color: AppColors.accentCyan.withOpacity(0.3), blurRadius: 16)]),
          child: FilledButton.icon(onPressed: () => _showCreateListDialog(context),
            icon: const Icon(Icons.add_rounded), label: Text('Crear Primera Lista', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: AppColors.bgDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
        ),
      ],
    )));
  }

  Widget _buildListCard(BuildContext context, GameList list, BacklogProvider provider, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 60)),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(opacity: value,
        child: Transform.translate(offset: Offset(0, 15 * (1 - value)), child: child)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A4A))),
        child: Material(color: Colors.transparent, child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/collections/${list.id}'),
          child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Container(width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.collections_bookmark_rounded, color: Colors.white, size: 24)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(list.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              if (list.description != null && list.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(list.description!, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13))],
              const SizedBox(height: 6),
              FutureBuilder<int>(
                future: provider.getListItemCount(list.id),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.accentCyan.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text('$count ${count == 1 ? 'juego' : 'juegos'}',
                      style: GoogleFonts.inter(color: AppColors.accentCyan, fontSize: 11, fontWeight: FontWeight.w600)));
                },
              ),
            ])),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _showCreateListDialog(context, existingList: list);
                else if (value == 'delete') _showDeleteConfirmation(context, list);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [
                  Icon(Icons.edit_rounded, size: 18, color: AppColors.accentCyan), SizedBox(width: 12), Text('Editar')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [
                  Icon(Icons.delete_rounded, size: 18, color: AppColors.accentRose), SizedBox(width: 12),
                  Text('Eliminar', style: TextStyle(color: AppColors.accentRose))])),
              ],
            ),
          ])),
        )),
      ),
    );
  }

  void _showCreateListDialog(BuildContext context, {GameList? existingList}) {
    final nameCtrl = TextEditingController(text: existingList?.name ?? '');
    final descCtrl = TextEditingController(text: existingList?.description ?? '');
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text(existingList == null ? 'Nueva Colección' : 'Editar Colección'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, autofocus: true, style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Nombre', hintText: 'Ej: RPGs favoritos')),
        const SizedBox(height: 16),
        TextField(controller: descCtrl, style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Descripción (opcional)', hintText: 'Describe tu colección...'), maxLines: 2),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () async {
          final name = nameCtrl.text.trim();
          if (name.isEmpty) return;
          final p = context.read<BacklogProvider>();
          bool ok;
          if (existingList == null) {
            ok = await p.createGameList(name: name, description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null);
          } else {
            ok = await p.updateGameList(listId: existingList.id, name: name, description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null);
          }
          if (ok && context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(existingList == null ? 'Colección creada' : 'Colección actualizada')));
          }
        }, child: Text(existingList == null ? 'Crear' : 'Guardar')),
      ],
    ));
  }

  void _showDeleteConfirmation(BuildContext context, GameList list) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('¿Eliminar colección?'),
      content: Text('Se eliminará "${list.name}" y todos sus juegos asociados serán desvinculados.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        TextButton(onPressed: () async {
          Navigator.pop(context);
          final ok = await context.read<BacklogProvider>().deleteGameList(list.id);
          if (ok && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Colección eliminada')));
        }, child: const Text('Eliminar', style: TextStyle(color: AppColors.accentRose))),
      ],
    ));
  }
}
