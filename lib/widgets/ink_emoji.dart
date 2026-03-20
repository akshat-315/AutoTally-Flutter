import 'package:flutter/material.dart';

class InkEmoji extends StatelessWidget {
  final String emoji;
  final double fontSize;

  const InkEmoji(this.emoji, {super.key, this.fontSize = 22});

  static const _greyscaleMatrix = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: _greyscaleMatrix,
      child: Text(emoji, style: TextStyle(fontSize: fontSize)),
    );
  }
}
