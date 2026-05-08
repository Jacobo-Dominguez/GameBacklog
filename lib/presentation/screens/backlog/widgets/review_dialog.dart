import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:game_backlog/presentation/providers/backlog_provider.dart';
import 'package:game_backlog/core/theme/app_theme.dart';

class ReviewDialog extends StatefulWidget {
  final String? entryId; // gameId for new, null for edit
  final String? reviewId; // reviewId for edit
  final String? initialTitle;
  final String? initialContent;
  final bool initialIsSpoiler;
  final Function(String title, String content, bool isSpoiler)? onReviewSubmit;

  const ReviewDialog({
    super.key,
    this.entryId,
    this.reviewId,
    this.initialTitle,
    this.initialContent,
    this.initialIsSpoiler = false,
    this.onReviewSubmit,
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
    final isEdit = widget.reviewId != null;

    return Dialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? 'Editar Reseña' : 'Nueva Reseña',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Título corto',
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  hintText: 'ej. Obra Maestra, Muy difícil...',
                  hintStyle: const TextStyle(color: Colors.white12),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                maxLength: 50,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: '¿Qué te pareció el juego?',
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 1000,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Contiene Spoilers', style: TextStyle(color: Colors.white, fontSize: 14)),
                value: _isSpoiler,
                activeColor: AppColors.accentRose,
                onChanged: (val) => setState(() => _isSpoiler = val),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('CANCELAR'),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: AppColors.accentGradient,
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('GUARDAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveReview() async {
    setState(() => _isLoading = true);
    
    if (widget.onReviewSubmit != null) {
      await widget.onReviewSubmit!(
        _titleController.text.trim(),
        _contentController.text.trim(),
        _isSpoiler,
      );
    } else {
      // Legacy or internal provider call logic
      // But we prefer onReviewSubmit callback from GameDetailScreen
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }
}
