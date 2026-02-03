import 'package:flutter/material.dart';

const double kTabBarHeight = 58;
const double kTabBarBottomGap = 12;

double floatingTabBarBottomInset(BuildContext context) {
  return MediaQuery.paddingOf(context).bottom + kTabBarHeight + kTabBarBottomGap;
}
