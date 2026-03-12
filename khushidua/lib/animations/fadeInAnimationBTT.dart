import 'package:flutter/material.dart';

class FadeInAnimationBTT extends StatefulWidget {
  const FadeInAnimationBTT({super.key, required this.child, required this.delay});

  final Widget child;
  final double delay;

  @override
  State<FadeInAnimationBTT> createState() => _FadeInAnimationBTTState();
}

class _FadeInAnimationBTTState extends State<FadeInAnimationBTT>
    with TickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;
  late Animation<double> animation2;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    animation2 = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {});
      });

    animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeIn),
    )..addListener(() {
        setState(() {});
      });

    // Start with delay
    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(Duration(milliseconds: (200 * widget.delay).round()));
    if (mounted) {
      controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, animation2.value),
      child: Opacity(
        opacity: animation.value,
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}