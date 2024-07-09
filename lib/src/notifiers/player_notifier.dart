import 'package:flutter/material.dart';

///
/// The new State-Manager for Chewie!
/// Has to be an instance of Singleton to survive
/// over all State-Changes inside chewie
///
///

enum NaviationType { FORWARD, BACKWARD }

class PlayerNotifier extends ChangeNotifier {
  PlayerNotifier._(
    bool hideStuff,
  ) : _hideStuff = hideStuff;

  bool _hideStuff;

  bool get hideStuff => _hideStuff;

  set hideStuff(bool value) {
    _hideStuff = value;
    notifyListeners();
  }

  // ignore: prefer_constructors_over_static_methods
  static PlayerNotifier init() {
    return PlayerNotifier._(
      true,
    );
  }

  int focusedButtonIndex = -1;

  void setFocusedButtonIndex(int index) {
    print("OKAY => SETTING INDEX == $index");
    focusedButtonIndex = index;
    notifyListeners();
  }

  int maxFocusIndex = 7;

  int getNextFocusIndex(NaviationType type) {
    if (type == NaviationType.FORWARD) {
      if (focusedButtonIndex == maxFocusIndex) {
        return 1;
      }
      if (focusedButtonIndex < maxFocusIndex) {
        return focusedButtonIndex + 1;
      }
    } else {
      if (focusedButtonIndex == -1) {
        return maxFocusIndex;
      }
      return focusedButtonIndex - 1;
    }

    return focusedButtonIndex;
  }

  void naviagte(NaviationType type) {
    focusedButtonIndex = getNextFocusIndex(type);
    notifyListeners();
  }

  bool optionsDialogIsShowing = false;
  bool shouldOptionDialogRequestFocus = false;

  void setOptionsDialogIsShowing(bool value) {
    optionsDialogIsShowing = value;
    notifyListeners();
  }

  void setShouldOptionDialogRequestFocus(bool value) {
    shouldOptionDialogRequestFocus = value;
    notifyListeners();
  }
}
