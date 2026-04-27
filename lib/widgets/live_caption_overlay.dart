import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/caption_provider.dart';
import '../providers/settings_provider.dart';

class LiveCaptionOverlay extends StatelessWidget {
  final Widget child;

  const LiveCaptionOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final captionProvider = context.watch<CaptionProvider>();
    final caption = captionProvider.currentCaption;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          child,
          if (settingsProvider.isLiveCaptions && caption != null)
            Positioned(
              bottom: 120, // Positioned safely above standard bottom nav bars
              left: 24,
              right: 24,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
