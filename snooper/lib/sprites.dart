import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class Sprites {
  static late final ui.Image flags;
  static late final ui.Image ranks;
  static late final ui.Image padlock;

  static Future<void> load() async {
    flags = await _decode('assets/sprites/nationflags.png');
    ranks = await _decode('assets/sprites/rankstrip.gif');
    padlock = await _decode('assets/sprites/nopadlock.gif');
  }

  static Future<ui.Image> _decode(String path) async {
    final bytes = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
