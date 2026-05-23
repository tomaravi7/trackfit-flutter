import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool animateHover;

  const GlassCard({
    Key? key,
    required this.child,
    this.padding,
    this.borderRadius = 20.0,
    this.animateHover = false,
  }) : super(key: key);

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.985).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget cardContent = Container(
      padding: widget.padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.black.withOpacity(0.35) 
            : Colors.white.withOpacity(0.55),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withOpacity(_isHovered ? 0.08 : 0.05),
                  Colors.white.withOpacity(_isHovered ? 0.02 : 0.01),
                ]
              : [
                  Colors.white.withOpacity(0.7),
                  Colors.white.withOpacity(0.4),
                ],
        ),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(_isHovered ? 0.12 : 0.06) 
              : Colors.black.withOpacity(0.08),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? (_isHovered 
                    ? const Color(0xff6366f1).withOpacity(0.08) 
                    : Colors.black.withOpacity(0.3))
                : Colors.black.withOpacity(0.04),
            blurRadius: _isHovered ? 24 : 16,
            offset: Offset(0, _isHovered ? 8 : 4),
          )
        ],
      ),
      child: widget.child,
    );

    if (widget.animateHover) {
      return MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          _controller.forward();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _controller.reverse();
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
              child: cardContent,
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: cardContent,
      ),
    );
  }
}
