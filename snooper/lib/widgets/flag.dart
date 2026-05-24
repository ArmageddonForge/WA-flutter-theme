import 'package:flutter/widgets.dart';
import 'package:wa/wa.dart';

import '../sprites.dart';
import 'sprite_cell.dart';

class Flag extends StatelessWidget {
  const Flag(this.location, {super.key, this.scale = waScale});

  final int location;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final int idx = (location >= 1 && location <= 84) ? location - 1 : 49;
    return SpriteCell(
      sheet: Sprites.flags,
      src: Rect.fromLTWH(idx * 22.0 + 1, 1, 20, 16),
      scale: scale,
    );
  }
}

class Rank extends StatelessWidget {
  const Rank(this.rank, {super.key, this.scale = waScale});

  final int rank;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final int r = (rank >= 0 && rank <= 13) ? rank : 12;
    return SpriteCell(
      sheet: Sprites.ranks,
      src: Rect.fromLTWH(0, r * 17.0, 48, 17),
      scale: scale,
    );
  }
}

class Padlock extends StatelessWidget {
  const Padlock({super.key, required this.locked, this.scale = waScale});

  final bool locked;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SpriteCell(
      sheet: Sprites.padlock,
      src: Rect.fromLTWH(locked ? 16 : 0, 0, 16, 16),
      scale: scale,
    );
  }
}
