import 'dart:async';
import 'package:flutter/foundation.dart';

/// Provides a global mechanism to broadcast live captions to the screen.
class CaptionProvider extends ChangeNotifier {
  String? _currentCaption;
  Timer? _captionTimer;

  String? get currentCaption => _currentCaption;

  /// Displays a caption on the screen for the given [duration].
  void showCaption(String text, {Duration duration = const Duration(seconds: 5)}) {
    _currentCaption = text;
    notifyListeners();

    _captionTimer?.cancel();
    _captionTimer = Timer(duration, () {
      _currentCaption = null;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _captionTimer?.cancel();
    super.dispose();
  }
}
