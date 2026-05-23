import 'package:flutter/widgets.dart';

import 'theme.dart';

class WADialog extends StatelessWidget {
  const WADialog({
    super.key,
    this.title,
    required this.child,
    this.width,
    this.height,
  });

  final String? title;
  final Widget child;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width,
        height: height,
        padding: EdgeInsets.all(waPx(16)),
        decoration: BoxDecoration(
          color: WAColors.black,
          border: Border.all(
            color: WAColors.grey,
            width: WAMetrics.borderWidth * 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: WAFonts.bodyOn(WAColors.yellow)),
              SizedBox(height: waPx(8)),
            ],
            DefaultTextStyle(
              style: WAFonts.bodyOn(WAColors.white),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

Future<T?> showWADialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = false,
}) {
  return Navigator.of(context).push<T>(
    PageRouteBuilder<T>(
      opaque: false,
      barrierColor: const Color(0x00000000),
      barrierDismissible: barrierDismissible,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        Widget dialog = builder(context);
        if (barrierDismissible) {
          dialog = Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              dialog,
            ],
          );
        }
        return dialog;
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          child,
    ),
  );
}
