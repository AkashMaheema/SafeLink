import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/admin_service.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<bool> _confirmDelete(BuildContext context, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text(
        'Delete User',
        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
      ),
      content: Text(
        message,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.grey.shade600,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE12626),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Delete',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

enum _UserFilter { all, users, admins, government }

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _adminService = AdminService();
  _UserFilter _filter = _UserFilter.all;

  List<UserModel> _applyFilter(List<UserModel> users) => switch (_filter) {
    _UserFilter.all => users,
    _UserFilter.users =>
      users
          .where((u) => u.role == UserRole.user || u.role == UserRole.regular)
          .toList(),
    _UserFilter.admins => users.where((u) => u.role == UserRole.admin).toList(),
    _UserFilter.government =>
      users.where((u) => u.role == UserRole.government).toList(),
  };

  static Color _roleColor(UserRole role) => switch (role) {
    UserRole.admin => const Color(0xFFE12626),
    UserRole.government => const Color(0xFF2563EB),
    UserRole.user || UserRole.regular => const Color(0xFF6B7280),
  };

  static String _roleLabel(UserRole role) => switch (role) {
    UserRole.admin => 'Admin',
    UserRole.government => 'Government',
    UserRole.user => 'User',
    UserRole.regular => 'Regular',
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Manage Users',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  StreamBuilder<int>(
                    stream: _adminService.streamUserCount(),
                    builder: (context, snap) {
                      final count = snap.data ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EEFF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$count users',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Filter chips ──────────────────────────────────────────────
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _Chip(
                    label: 'All',
                    selected: _filter == _UserFilter.all,
                    onTap: () => setState(() => _filter = _UserFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    label: 'Users',
                    selected: _filter == _UserFilter.users,
                    onTap: () => setState(() => _filter = _UserFilter.users),
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    label: 'Admins',
                    selected: _filter == _UserFilter.admins,
                    onTap: () => setState(() => _filter = _UserFilter.admins),
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    label: 'Government',
                    selected: _filter == _UserFilter.government,
                    onTap: () =>
                        setState(() => _filter = _UserFilter.government),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── List ──────────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: _adminService.streamAllUsers(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE12626),
                        strokeWidth: 2,
                      ),
                    );
                  }

                  final filtered = _applyFilter(snap.data ?? []);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 22),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 28,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 48,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No users found',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontFamily: 'Poppins',
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _UserCard(
                        user: filtered[i],
                        adminService: _adminService,
                        roleColor: _roleColor(filtered[i].role),
                        roleLabel: _roleLabel(filtered[i].role),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── User card ─────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final UserModel user;
  final AdminService adminService;
  final Color roleColor;
  final String roleLabel;

  const _UserCard({
    required this.user,
    required this.adminService,
    required this.roleColor,
    required this.roleLabel,
  });

  String get _initial {
    if (user.displayName.isNotEmpty) return user.displayName[0].toUpperCase();
    if (user.email.isNotEmpty) return user.email[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: roleColor.withValues(alpha: 0.12),
            child: Text(
              _initial,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: roleColor,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name + email + role badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName.isNotEmpty ? user.displayName : 'Unknown',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 15,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    roleLabel,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: roleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Popup menu
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) async {
              if (value == 'delete') {
                final ok = await _confirmDelete(
                  context,
                  'Delete "${user.displayName.isNotEmpty ? user.displayName : user.email}"? This cannot be undone.',
                );
                if (ok) await adminService.deleteUser(user.uid);
              } else {
                await adminService.setUserRole(
                  user.uid,
                  UserRoleX.fromString(value),
                );
              }
            },
            itemBuilder: (_) => [
              _menuItem(
                'user',
                'Make User',
                Icons.person_outline_rounded,
                const Color(0xFF6B7280),
              ),
              _menuItem(
                'admin',
                'Make Admin',
                Icons.admin_panel_settings_outlined,
                const Color(0xFFE12626),
              ),
              _menuItem(
                'government',
                'Make Government',
                Icons.account_balance_outlined,
                const Color(0xFF2563EB),
              ),
              const PopupMenuDivider(),
              _menuItem(
                'delete',
                'Delete User',
                Icons.delete_outline_rounded,
                const Color(0xFFE12626),
                textColor: const Color(0xFFE12626),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    String label,
    IconData icon,
    Color iconColor, {
    Color? textColor,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chip ──────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFE8E8) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? const Color(0xFFE12626)
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontFamily: 'Poppins',
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
