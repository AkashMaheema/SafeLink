import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';

class QuickActionsSheet extends StatelessWidget {
  const QuickActionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Actions',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Default SOS Action
          Text(
            'Default SOS Action',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: settingsProvider.defaultSosAction,
                isExpanded: true,
                dropdownColor: colorScheme.surface,
                icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurface),
                items: ['Notify Contacts', 'Call Police (119)', 'Sound Loud Alarm']
                    .map((action) => DropdownMenuItem(
                          value: action,
                          child: Text(
                            action,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    context.read<SettingsProvider>().setDefaultSosAction(value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Shake-to-SOS
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Shake-to-SOS',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            subtitle: Text(
              'Trigger an emergency alert by shaking your phone.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            value: settingsProvider.isShakeToSos,
            onChanged: (value) => context.read<SettingsProvider>().setShakeToSos(value),
            activeColor: colorScheme.primary,
          ),
          const SizedBox(height: 12),

          // Silent SOS
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Silent SOS',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            subtitle: Text(
              'Bypass alarms to stay hidden in dangerous situations.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            value: settingsProvider.isSilentSos,
            onChanged: (value) => context.read<SettingsProvider>().setSilentSos(value),
            activeColor: colorScheme.primary,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
