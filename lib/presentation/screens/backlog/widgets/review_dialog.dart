import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/backlog_provider.dart';

class ReviewDialog extends StatefulWidget {
  final String entryId;
  final String? initialTitle;
  final String? initialContent;
  final bool initialIsSpoiler;

  const ReviewDialog({
    super.key,
    required this.entryId,
    this.initialTitle,
    this.initialContent,
    this.initialIsSpoiler = false,
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late bool _isSpoiler;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
    _isSpoiler = widget.initialIsSpoiler;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initialContent == null ? 'Escribir Reseña' : 'Editar Reseña',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título corto (ej. Obra Maestra)',
                border: OutlineInputBorder(),
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '¿Qué te pareció el juego?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: 1000,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Contiene Spoilers'),
              subtitle: const Text('Avisa a otros usuarios'),
              value: _isSpoiler,
              onChanged: (val) => setState(() => _isSpoiler = val),
              secondary: const Icon(Icons.warning_amber_rounded),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.initialContent != null)
                  TextButton(
                    onPressed: _isLoading ? null : _deleteReview,
                    child: const Text('Borrar', style: TextStyle(color: Colors.red)),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveReview,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveReview() async {
    setState(() => _isLoading = true);
    
    final success = await context.read<BacklogProvider>().updateReview(
      entryId: widget.entryId,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      isSpoiler: _isSpoiler,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reseña guardada correctamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar la reseña')),
        );
      }
    }
  }

  Future<void> _deleteReview() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar reseña?'),
        content: const Text('Esta acción eliminará el título, las notas y la puntuación de tu reseña.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Borrar', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final success = await context.read<BacklogProvider>().deleteReview(widget.entryId);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reseña eliminada')),
        );
      }
    }
  }
}
