import 'package:flutter/widgets.dart';

class StackedGradient extends StatelessWidget {
  const StackedGradient(this._gradients, {super.key});
  final List<Gradient> _gradients;

  @override
  Widget build(final BuildContext context) {
    if (_gradients.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(gradient: _gradients.first),
      child: _gradients.length > 1
          ? StackedGradient(_gradients.sublist(1))
          : null,
    );
  }
}
