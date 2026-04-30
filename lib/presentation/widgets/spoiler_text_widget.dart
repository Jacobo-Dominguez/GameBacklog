import 'package:flutter/material.dart';

class SpoilerTextWidget extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const SpoilerTextWidget({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  State<SpoilerTextWidget> createState() => _SpoilerTextWidgetState();
}

class _SpoilerTextWidgetState extends State<SpoilerTextWidget> {
  bool _isRevealed = false;

  @override
  Widget build(BuildContext context) {
    if (_isRevealed) {
      return Text(
        widget.text,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isRevealed = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          widget.text,
          style: (widget.style ?? const TextStyle()).copyWith(
            color: Colors.transparent, // Ocultar el texto detrás del color
            shadows: [],
          ),
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        ),
      ),
    );
  }
}
