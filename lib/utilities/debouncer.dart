// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/cupertino.dart';

class Debouncer {
  final int milliseconds;
  Timer? _timer;
  Debouncer({
    required this.milliseconds,
  });
  run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(microseconds: milliseconds), action);
  }
}
