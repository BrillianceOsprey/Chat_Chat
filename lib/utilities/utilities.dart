import 'package:flutter/cupertino.dart';

class Utilities {
  static bool isKeyBoardShowing() {
    // ignore: unnecessary_null_comparison
    if (WidgetsBinding.instance != null) {
      // return WidgetsBinding.instance.window.viewInsets.bottom > 0;
      return WidgetsBinding.instance.platformDispatcher.views.first.physicalSize
              .aspectRatio >
          0;
    } else {
      return false;
    }
  }

  static closeKeyboard(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }
}
