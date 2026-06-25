import 'package:flutter/material.dart';

class ThemeController {
  static final mode = ValueNotifier<ThemeMode>(ThemeMode.system);

  static void toggle() {
    mode.value =
        mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  static bool isDark(BuildContext context) {
    if (mode.value == ThemeMode.dark) return true;
    if (mode.value == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }
}
