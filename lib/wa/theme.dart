import 'package:flutter/widgets.dart';

/// All physical sizes in WA widgets are multiples of this constant.
/// 1.0 is the original 1999 pixel grid; 2.0 doubles for modern displays.
const double waScale = 2.0;

/// Snap a logical pixel size to the WA scale grid.
double waPx(num n) => n * waScale;

class WAColors {
  static const Color black = Color(0xFF000000);
  static const Color darkBlue = Color(0xFF000040);
  static const Color grey = Color(0xFF808080);
  static const Color white = Color(0xFFFFFFFF);
  static const Color yellow = Color(0xFFFFFF00);
  static const Color selectionRed = Color(0xFFFF0000);
  static const Color pink = Color(0xFFFEB6A8);

  /// Used for both text and border on any disabled control.
  static const Color disabled = Color(0xFF404040);

  /// Vertical gradient used for the background of full-screen menus.
  static const Gradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [black, darkBlue],
  );
}

class WAFonts {
  /// Bundled font; falls back to a system Tahoma/sans if missing.
  static const String family = 'DejaVuSansCondensed';
  static const List<String> fallback = ['Tahoma', 'Verdana', 'Droid Sans'];

  static const TextStyle body = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontWeight: FontWeight.bold,
    fontSize: 9.0 * waScale,
    color: WAColors.grey,
    height: 1.2,
  );

  static TextStyle bodyOn(Color color) => body.copyWith(color: color);

  /// Row height for list-style controls (list box rows, dropdown menu rows).
  static double get rowHeight => body.fontSize! * body.height!;
}

/// Stub for WA UI sound effects. Call sites use the data-directory-relative
/// paths from the game spec (e.g. 'fesfx/softclick.wav') so a real audio
/// backend can drop in later without touching widget code.
class WASound {
  WASound._();
  static void play(String relPath) {}
}

/// Standard border widths and paddings, expressed in WA-scaled pixels.
class WAMetrics {
  static double get borderWidth => waPx(1);
  static double get focusBorderWidth => waPx(1);
  static double get controlPadH => waPx(6);
  static double get controlPadV => waPx(3);
  static double get groupPad => waPx(6);
  static double get gap => waPx(4);
}
