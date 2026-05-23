import 'dart:math';
import 'package:flutter/material.dart';

class CalorieRing extends StatefulWidget {
  final double current;
  final double target;
  final double remaining;

  const CalorieRing({
    Key? key,
    required this.current,
    required this.target,
    required this.remaining,
  }) : super(key: key);

  @override
  State<CalorieRing> createState() => _CalorieRingState();
}

class _CalorieRingState extends State<CalorieRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _prevPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _setupAnimation();
  }

  @override
  void didUpdateWidget(covariant CalorieRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current || oldWidget.target != widget.target) {
      _prevPercentage = oldWidget.target > 0 ? (oldWidget.current / oldWidget.target) : 0.0;
      _setupAnimation();
    }
  }

  void _setupAnimation() {
    final double targetPercentage = widget.target > 0 ? (widget.current / widget.target) : 0.0;
    _animation = Tween<double>(
      begin: _prevPercentage,
      end: targetPercentage.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(150, 150),
          painter: _CalorieRingPainter(
            percentage: _animation.value,
          ),
          child: SizedBox(
            width: 150,
            height: 150,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Remaining',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.zinc.shade500
                          : Colors.grey.shade600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.remaining.round()}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'of ${widget.target.round()} kcal',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.zinc.shade400
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CalorieRingPainter extends CustomPainter {
  final double percentage;

  _CalorieRingPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 8;
    const strokeWidth = 10.0;

    // 1. Draw base/track track
    final trackPaint = Paint()
      ..color = const Color(0xff1d1d29).withOpacity(0.4)
      ..strokeWidth = 7.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Draw glow layer (thicker stroke with blur)
    if (percentage > 0.01) {
      final glowPaint = Paint()
        ..strokeWidth = strokeWidth + 4.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0)
        ..shader = const SweepGradient(
          colors: [
            Color(0xff10b981),
            Color(0xff34d399),
            Color(0xff6ee7b7),
          ],
          transform: GradientRotation(-pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * percentage,
        false,
        glowPaint,
      );
    }

    // 3. Draw primary colored gradient arc
    if (percentage > 0.0) {
      final progressPaint = Paint()
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..shader = const SweepGradient(
          colors: [
            Color(0xff10b981),
            Color(0xff34d399),
            Color(0xff6ee7b7),
          ],
          transform: GradientRotation(-pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * percentage,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CalorieRingPainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}
