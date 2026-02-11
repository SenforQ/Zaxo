import 'package:flutter/material.dart';

const double kTabBarHeight = 58;
const double kTabBarBottomGap = 12;

const LinearGradient kHomeBackgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF260FA9),
    Color(0xFF4a2fc9),
    Color(0xFF1a0d5c),
  ],
);

double floatingTabBarBottomInset(BuildContext context) {
  return MediaQuery.paddingOf(context).bottom + kTabBarHeight + kTabBarBottomGap;
}
