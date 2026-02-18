import 'package:flutter/material.dart';

class SampleRecordProvider extends ChangeNotifier {
  int _sampleCount = 0;
  bool _isRecording = false;

  int get sampleCount => _sampleCount;
  bool get isRecording => _isRecording;

  void startRecording() {
    _isRecording = true;
    notifyListeners();
    // Simulate recording logic here if needed, or just handle UI state
  }

  void stopRecording() {
    _isRecording = false;
    notifyListeners();
  }
}
