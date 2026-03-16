import 'package:emartconsumer/utils/DarkThemePreference.dart';
import 'package:flutter/foundation.dart';

class DarkThemeProvider with ChangeNotifier {
  DarkThemePreference darkThemePreference = DarkThemePreference();
  bool _darkTheme = false;

  bool get darkTheme => _darkTheme;

  bool getThem() {
    return darkTheme == 0
        ? true
        : darkTheme == 1
        ? false
        : false;
  }

  set darkTheme(bool value) {
    _darkTheme = value;
    darkThemePreference.setDarkTheme(value);
    notifyListeners();
  }
}
