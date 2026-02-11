import 'package:flutter/material.dart';

import '../constants/app_ui.dart';
import 'stars_background_layer.dart';

class GradientBubblesBackground extends StatelessWidget {
  const GradientBubblesBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: kHomeBackgroundGradient,
          ),
        ),
        const StarsBackgroundLayer(
          starColor: Color(0x22FFFFFF),
          starCount: 32,
          maxStarRadius: 24.0,
          minStarRadius: 10.0,
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}
