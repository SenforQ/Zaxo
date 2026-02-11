import 'dart:math' as math;

import 'package:flutter/material.dart';

class StarsBackgroundLayer extends StatefulWidget {
  const StarsBackgroundLayer({
    super.key,
    this.child,
    this.starColor = const Color(0x28FFFFFF),
    this.starCount = 24,
    this.maxStarRadius = 24.0,
    this.minStarRadius = 10.0,
    this.twinkleDuration = const Duration(milliseconds: 2500),
  });

  final Widget? child;
  final Color starColor;
  final int starCount;
  final double maxStarRadius;
  final double minStarRadius;
  final Duration twinkleDuration;

  @override
  State<StarsBackgroundLayer> createState() => _StarsBackgroundLayerState();
}

class _StarPlacement {
  _StarPlacement(this.x, this.y, this.r, this.rotation, this.phase);

  final double x;
  final double y;
  final double r;
  final double rotation;
  final double phase;
}

class _StarsBackgroundLayerState extends State<StarsBackgroundLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<_StarPlacement>? _stars;
  Size? _lastSize;
  static const int _placementSeed = 42;
  static const double _overlapPadding = 3.0;
  static const int _maxPlacementAttempts = 80;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.twinkleDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_StarPlacement> _computeStars(Size size) {
    if (size.width <= 0 || size.height <= 0) return [];
    final rng = math.Random(_placementSeed);
    final list = <_StarPlacement>[];
    final minR = widget.minStarRadius;
    final maxR = widget.maxStarRadius;

    for (int i = 0; i < widget.starCount; i++) {
      _StarPlacement? placed;
      for (int attempt = 0; attempt < _maxPlacementAttempts; attempt++) {
        final r = minR + rng.nextDouble() * (maxR - minR);
        final padding = r + _overlapPadding;
        if (size.width <= 2 * padding || size.height <= 2 * padding) break;
        final x = padding + rng.nextDouble() * (size.width - 2 * padding);
        final y = padding + rng.nextDouble() * (size.height - 2 * padding);

        bool overlaps = false;
        for (final s in list) {
          final dx = x - s.x;
          final dy = y - s.y;
          final dist = math.sqrt(dx * dx + dy * dy);
          if (dist < r + s.r + _overlapPadding) {
            overlaps = true;
            break;
          }
        }
        if (!overlaps) {
          placed = _StarPlacement(
            x,
            y,
            r,
            rng.nextDouble() * 2 * math.pi,
            rng.nextDouble() * 2 * math.pi,
          );
          list.add(placed);
          break;
        }
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 0,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
        );
        if (size.width > 0 &&
            size.height > 0 &&
            (_lastSize == null ||
                _lastSize!.width != size.width ||
                _lastSize!.height != size.height)) {
          _lastSize = size;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _lastSize == size) {
              setState(() {
                _stars = _computeStars(size);
              });
            }
          });
        }
        final stars = _stars ?? [];
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _StarsPainter(
                starColor: widget.starColor,
                placements: stars,
                animationValue: _controller.value,
              ),
              size: size,
            ),
            if (widget.child != null) Positioned.fill(child: widget.child!),
          ],
        );
      },
    );
  }
}

class _StarsPainter extends CustomPainter {
  _StarsPainter({
    required this.starColor,
    required this.placements,
    required this.animationValue,
  });

  final Color starColor;
  final List<_StarPlacement> placements;
  final double animationValue;

  static const double _innerRadiusRatio = 0.382;

  @override
  void paint(Canvas canvas, Size size) {
    final unitPath = _buildUnitStarPath();
    for (final s in placements) {
      final twinkle = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(animationValue * 2 * math.pi + s.phase));
      final color = Color.fromRGBO(
        starColor.red,
        starColor.green,
        starColor.blue,
        starColor.opacity * twinkle,
      );
      canvas.save();
      canvas.translate(s.x, s.y);
      canvas.rotate(s.rotation);
      canvas.scale(s.r);
      canvas.drawPath(unitPath, Paint()..color = color);
      canvas.restore();
    }
  }

  Path _buildUnitStarPath() {
    const outerR = 1.0;
    final innerR = outerR * _innerRadiusRatio;
    const points = 5;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) {
    return oldDelegate.starColor != starColor ||
        oldDelegate.placements != placements ||
        (oldDelegate.animationValue - animationValue).abs() > 0.001;
  }
}
