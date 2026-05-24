import 'package:flutter/widgets.dart';
import 'state.dart';

class SnooperScope extends InheritedNotifier<SnooperState> {
  const SnooperScope({
    super.key,
    required SnooperState super.notifier,
    required super.child,
  });

  static SnooperState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SnooperScope>()!.notifier!;
}
