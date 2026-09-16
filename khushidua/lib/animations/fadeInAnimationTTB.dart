import 'package:flutter/material.dart';

import '../constants/theme.dart';

/// Fades and slides a child down into place, staggered by [delay].
///
/// [delay] is a stagger multiplier, not a duration: 1 is one step, 2 is two.
class FadeInAnimationTTB extends StatefulWidget {
  const FadeInAnimationTTB({
    super.key,
    required this.child,
    required this.delay,
  });

  final Widget child;
  final double delay;

  @override
  State<FadeInAnimationTTB> createState() => _FadeInAnimationTTBState();
}

class _FadeInAnimationTTBState extends State<FadeInAnimationTTB>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: AppMotion.slow,
    vsync: this,
  );

  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<double> _offset = Tween<double>(
    begin: -24,
    end: 0,
  ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.curve));

  @override
  void initState() {
    super.initState();
    _start();
  }

  /// Started from initState rather than build: driving the controller from
  /// build restarts the animation on every rebuild.
  Future<void> _start() async {
    final stagger = (60 * widget.delay).round();
    if (stagger > 0) {
      await Future.delayed(Duration(milliseconds: stagger));
    }
    if (mounted) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder rebuilds only the transform, not the whole subtree.
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _offset.value),
        child: Opacity(opacity: _opacity.value, child: child),
      ),
    );
  }
}
