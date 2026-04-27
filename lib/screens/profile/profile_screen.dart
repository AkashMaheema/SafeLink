import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import 'accessibility_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = auth.userModel;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.notifications_none_rounded),
                          color: colorScheme.onSurface,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                  backgroundImage: user.photoUrl != null
                                      ? NetworkImage(user.photoUrl!)
                                      : null,
                                  child: user.photoUrl == null
                                      ? Text(
                                          user.displayName.isNotEmpty
                                              ? user.displayName[0]
                                                    .toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w700,
                                            color: colorScheme.onSurface,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF121212),
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user.isVerified
                                            ? 'Verified Account'
                                            : 'Unverified Account',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: const [
                                Expanded(
                                  child: _ActionPill(
                                    icon: Icons.shield_outlined,
                                    label: 'Verify Identity',
                                    isDanger: true,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: _ActionPill(
                                    icon: Icons.notifications_active_outlined,
                                    label: 'Setup SOS',
                                    isDanger: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Expanded(
                                  child: _ActionPill(
                                    icon: Icons.verified_user_outlined,
                                    label: 'Trusted Contacts',
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: _ActionPill(
                                    icon: Icons.article_outlined,
                                    label: 'My Reports',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            Expanded(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _SettingsRow(
                                    icon: Icons.email_outlined,
                                    label: 'Email',
                                    trailingText: user.email,
                                  ),
                                  _SettingsRow(
                                    icon: Icons.language_outlined,
                                    label: 'Language & Accessibility',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const AccessibilityScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _SettingsRow(
                                    icon: Icons.dark_mode_outlined,
                                    label: 'Dark Mode',
                                    trailing: Switch(
                                      value: themeProvider.isDarkMode,
                                      onChanged: (value) {
                                        context
                                            .read<ThemeProvider>()
                                            .setDarkMode(value);
                                      },
                                      activeThumbColor: const Color(0xFFE02323),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  _SettingsRow(
                                    icon: Icons.key_outlined,
                                    label: 'Change PIN',
                                    onTap: () {},
                                  ),
                                  _SettingsRow(
                                    icon: Icons.contact_phone_outlined,
                                    label: 'Emergency Contacts',
                                    onTap: () {},
                                  ),
                                  _SettingsRow(
                                    icon: Icons.lock_outline,
                                    label: 'Privacy Controls',
                                    onTap: () {},
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton.icon(
                                onPressed: () => _confirmSignOut(context),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFE02323),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.logout,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Sign Out',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<AuthProvider>().signOut();
    }
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDanger;

  const _ActionPill({
    required this.icon,
    required this.label,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isDanger
        ? colorScheme.errorContainer.withValues(alpha: 0.55)
        : colorScheme.surfaceContainerHighest;
    final fgColor = isDanger
        ? colorScheme.onErrorContainer
        : colorScheme.onSurface;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: fgColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fgColor,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingText;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.trailingText,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rightWidget =
        trailing ??
        (trailingText != null
            ? Text(
                trailingText!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              )
            : Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Icon(icon, color: colorScheme.onSurface, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailingText != null)
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: rightWidget,
                ),
              )
            else
              rightWidget,
          ],
        ),
      ),
    );
  }
}
