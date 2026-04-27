import 'package:flutter/material.dart';

class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  bool _highContrast = false;
  bool _largerText = false;
  bool _voiceAssistance = false;
  bool _vibrationOnly = false;
  bool _liveCaptions = false;
  bool _voiceControl = false;
  bool _largeTouchTargets = false;
  bool _assistiveGestures = false;
  bool _simplifiedMode = false;
  bool _plainLanguageAlerts = false;

  void _resetAll() {
    setState(() {
      _highContrast = false;
      _largerText = false;
      _voiceAssistance = false;
      _vibrationOnly = false;
      _liveCaptions = false;
      _voiceControl = false;
      _largeTouchTargets = false;
      _assistiveGestures = false;
      _simplifiedMode = false;
      _plainLanguageAlerts = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final switchTheme = SwitchTheme.of(context).copyWith(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF79ABE7);
        }
        return const Color(0xFFE5EEF7);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFDCEAF8);
        }
        return const Color(0xFFEFF4FA);
      }),
      trackOutlineColor: WidgetStateProperty.all(const Color(0xFFC7D5E3)),
      trackOutlineWidth: WidgetStateProperty.all(1.0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Theme(
        data: Theme.of(context).copyWith(switchTheme: switchTheme),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 22,
                      ),
                      color: const Color(0xFF1C1C1C),
                    ),
                    const Expanded(
                      child: Text(
                        'Accessibility',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF101010),
                          fontFamily: 'Poppins',
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_none_rounded),
                      color: const Color(0xFF1C1C1C),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 34,
                      backgroundColor: Color(0xFFE0E5EA),
                      child: Icon(
                        Icons.person,
                        color: Color(0xFF57606B),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Personalize your experience',
                            style: TextStyle(
                              color: Color(0xFF121212),
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Adjust contrast, text size, motion,\nand audio cues.',
                            style: TextStyle(
                              color: Color(0xFF646B76),
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _SectionTitle('Quick toggles'),
                const SizedBox(height: 8),
                _ToggleGroup(
                  children: [
                    _ToggleTile(
                      icon: Icons.contrast,
                      title: 'High contrast',
                      value: _highContrast,
                      onChanged: (value) =>
                          setState(() => _highContrast = value),
                    ),
                    _ToggleTile(
                      icon: Icons.zoom_in_outlined,
                      title: 'Larger text',
                      value: _largerText,
                      onChanged: (value) => setState(() => _largerText = value),
                    ),
                    _ToggleTile(
                      icon: Icons.mic_none_rounded,
                      title: 'Voice assistance',
                      value: _voiceAssistance,
                      showDivider: false,
                      onChanged: (value) =>
                          setState(() => _voiceAssistance = value),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _SectionTitle('Hearing'),
                const SizedBox(height: 8),
                _ToggleGroup(
                  children: [
                    _ToggleTile(
                      icon: Icons.volume_off_outlined,
                      title: 'Vibration Only',
                      subtitle: 'Mute tones, keep haptics for alerts',
                      value: _vibrationOnly,
                      onChanged: (value) =>
                          setState(() => _vibrationOnly = value),
                    ),
                    _ToggleTile(
                      icon: Icons.subtitles_outlined,
                      title: 'Live Captions',
                      subtitle: 'Show captions for audio in calls',
                      value: _liveCaptions,
                      showDivider: false,
                      onChanged: (value) =>
                          setState(() => _liveCaptions = value),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _SectionTitle('Input & Shortcuts'),
                const SizedBox(height: 8),
                _ToggleGroup(
                  children: [
                    _ToggleTile(
                      icon: Icons.keyboard_voice_outlined,
                      title: 'Voice Control',
                      subtitle: 'Use voice to navigate and send alerts',
                      value: _voiceControl,
                      onChanged: (value) =>
                          setState(() => _voiceControl = value),
                    ),
                    _ActionTile(
                      icon: Icons.keyboard_outlined,
                      title: 'Quick Actions',
                      subtitle: 'Customize emergency shortcuts',
                      buttonLabel: 'Configure',
                      showDivider: false,
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _SectionTitle('Motor'),
                const SizedBox(height: 8),
                _ToggleGroup(
                  children: [
                    _ToggleTile(
                      icon: Icons.rectangle_outlined,
                      title: 'Large Touch Targets',
                      subtitle: 'Increase size of tappable areas',
                      value: _largeTouchTargets,
                      onChanged: (value) =>
                          setState(() => _largeTouchTargets = value),
                    ),
                    _ToggleTile(
                      icon: Icons.pan_tool_alt_outlined,
                      title: 'Assistive Gestures',
                      subtitle: 'Simplify complex gestures',
                      value: _assistiveGestures,
                      showDivider: false,
                      onChanged: (value) =>
                          setState(() => _assistiveGestures = value),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _SectionTitle('Cognitive'),
                const SizedBox(height: 8),
                _ToggleGroup(
                  children: [
                    _ToggleTile(
                      icon: Icons.horizontal_rule_rounded,
                      title: 'Simplified Mode',
                      subtitle: 'Reduce clutter and highlight key actions',
                      value: _simplifiedMode,
                      onChanged: (value) =>
                          setState(() => _simplifiedMode = value),
                    ),
                    _ToggleTile(
                      icon: Icons.priority_high_rounded,
                      title: 'Plain-Language Alerts',
                      subtitle: 'Show concise summaries on alerts',
                      value: _plainLanguageAlerts,
                      showDivider: false,
                      onChanged: (value) =>
                          setState(() => _plainLanguageAlerts = value),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tip: Enable High contrast for improved readability in sunlight\nor low-vision scenarios.',
                  style: TextStyle(
                    color: Color(0xFF5F6D7B),
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Accessibility settings saved'),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1E5CB8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          icon: const Icon(Icons.save_outlined, size: 20),
                          label: const Text(
                            'Save',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _resetAll,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1A1E27),
                            side: const BorderSide(color: Color(0xFFC4D4E5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          icon: const Icon(Icons.undo_rounded, size: 20),
                          label: const Text(
                            'Reset',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF6C6C6C),
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ToggleGroup extends StatelessWidget {
  final List<Widget> children;

  const _ToggleGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(children: children),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final bool showDivider;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colorScheme.outlineVariant))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurface),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool showDivider;
  final VoidCallback onPressed;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colorScheme.outlineVariant))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurface),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.onSurface,
              side: BorderSide(color: colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            icon: const Icon(Icons.settings_outlined, size: 18),
            label: Text(
              buttonLabel,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
