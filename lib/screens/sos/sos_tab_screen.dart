import 'package:flutter/material.dart';

/// Placeholder for the SOS tab content in bottom navigation.
///
/// This is intentionally empty for now. The SOS creation flow is still
/// accessible from Home via the dedicated SOS button.
class SosTabScreen extends StatelessWidget {
  const SosTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: Colors.white, body: SizedBox());
  }
}
