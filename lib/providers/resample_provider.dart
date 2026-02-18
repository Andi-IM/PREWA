import 'package:flutter/material.dart';

class ResampleProvider extends ChangeNotifier {
  void onProceed() {
    // Handle "Lanjut" action
    debugPrint('Proceed clicked');
  }

  void onPostpone() {
    // Handle "Tunda" action
    debugPrint('Postpone clicked');
  }
}
