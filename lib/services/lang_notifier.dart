import 'package:flutter/widgets.dart';

class LangNotifier extends InheritedNotifier<ValueNotifier<String>> {
  const LangNotifier({
    super.key,
    required ValueNotifier<String> notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ValueNotifier<String> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LangNotifier>()!.notifier!;
}
