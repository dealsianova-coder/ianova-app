import 'dart:async';

import 'package:flutter/material.dart';

/// Shows the IANOVA logo popping in twice, then fades into [next].
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.next});

  final Widget next;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    // Two pops: grow past size, settle, shrink a little, pop again, settle.
    _scale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.4, end: 1.12)
              .chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: 22),
      TweenSequenceItem(
          tween: Tween(begin: 1.12, end: 0.92)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 14),
      TweenSequenceItem(
          tween: Tween(begin: 0.92, end: 1.16)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 22),
      TweenSequenceItem(
          tween: Tween(begin: 1.16, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 18),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 24),
    ]).animate(_c);
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 12),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 88),
    ]).animate(_c);

    _c.forward();
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _done
          ? KeyedSubtree(key: const ValueKey('app'), child: widget.next)
          : Scaffold(
              key: const ValueKey('splash'),
              backgroundColor: Colors.white,
              body: Center(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (_, child) => Opacity(
                    opacity: _opacity.value,
                    child: Transform.scale(scale: _scale.value, child: child),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Image.asset('assets/images/ianova_logo.png'),
                  ),
                ),
              ),
            ),
    );
  }
}
