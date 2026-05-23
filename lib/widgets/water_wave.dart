import 'package:flutter/material.dart';

class WaterWave extends StatefulWidget {
  final double percentage;
  final double height;

  const WaterWave({
    Key? key,
    required this.percentage,
    this.height = 10.0,
  }) : super(key: key);

  @override
  State<WaterWave> createState() => _WaterWaveState();
}

class _WaterWaveState extends State<WaterWave> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.height / 2),
          child: Container(
            height: widget.height,
            width: double.infinity,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xff181822)
                : Colors.grey.shade100,
            child: CustomPaint(
              painter: _WaterWavePainter(
                percentage: widget.percentage.clamp(0.0, 1.0),
                animationValue: _controller.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaterWavePainter extends CustomPainter {
  final double percentage;
  final double animationValue;

  _WaterWavePainter({
    required this.percentage,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (percentage <= 0.0) return;

    final fillWidth = size.width * percentage;
    final fillRect = Rect.fromLTWH(0, 0, fillWidth, size.height);

    // 1. Draw base blue bar
    final basePaint = Paint()
      ..color = const Color(0xff0284c7) // sky-600
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(fillRect, basePaint);

    // 2. Draw animated wave stripes on top (clipped to the fill width)
    canvas.save();
    canvas.clipRect(fillRect);

    final stripePaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    const stripeWidth = 14.0;
    const spacing = 28.0;
    final offset = animationValue * spacing;

    // Draw diagonal stripes across the width
    for (double x = -stripeWidth; x < fillWidth + spacing; x += spacing) {
      final currentX = x + offset;
      
      final path = Path()
        ..moveTo(currentX, 0)
        ..lineTo(currentX + stripeWidth, 0)
        ..lineTo(currentX + stripeWidth - size.height, size.height)
        ..lineTo(currentX - size.height, size.height)
        ..close();

      canvas.drawPath(path, stripePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WaterWavePainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.animationValue != animationValue;
  }
}
