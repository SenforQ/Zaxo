import 'package:flutter/material.dart';

const String _bgAsset = 'assets/bg_home_nor.webp';

class GradientBubblesBackground extends StatelessWidget {
  const GradientBubblesBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 0,
          top: 0,
          width: size.width,
          height: size.height,
          child: Image.asset(
            _bgAsset,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}
