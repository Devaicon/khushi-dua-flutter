import 'package:flutter/material.dart';

import '../constants/theme.dart';

/// A shimmering placeholder shown while a list loads.
///
/// One sweep runs across the whole [child], so every [SkeletonBox] inside it
/// shimmers in step instead of each tile running its own animation.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, required this.child, this.onDark = false});

  final Widget child;

  /// For placeholders drawn over a dark background, such as the prayer
  /// screen's image; the default suits the light page.
  final bool onDark;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.onDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xffE6E8F0);
    final highlight = widget.onDark
        ? Colors.white.withValues(alpha: 0.20)
        : const Color(0xffF4F5F9);

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          // srcIn keeps only the boxes' shapes and paints the sweep into them.
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [base, highlight, base],
            stops: const [0.35, 0.5, 0.65],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            transform: _SweepTransform(_controller.value),
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

/// Slides the highlight from off the left edge to off the right edge.
class _SweepTransform extends GradientTransform {
  const _SweepTransform(this.progress);

  final double progress;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (progress * 2 - 1), 0, 0);
  }
}

/// A solid shape inside a [Skeleton]; its colour comes from the shimmer.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = AppRadius.sm,
  });

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
