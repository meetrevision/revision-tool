import 'package:flutter/widgets.dart';

class const StackedGradient(final List<Gradient> _gradients, {super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (_gradients.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(gradient: _gradients.first),
      child: _gradients.length > 1 ? StackedGradient(_gradients.sublist(1)) : null,
    );
  }
}
