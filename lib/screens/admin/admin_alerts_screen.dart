import 'package:flutter/material.dart';

import '../../models/alert_model.dart';
import '../../services/admin_service.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes} min ago';
  if (diff.inDays < 1) return '${diff.inHours} hr ago';
  return '${diff.inDays} day ago';
}

Future<bool> _confirmDelete(BuildContext context, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text(
        'Delete Alert',
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

enum _AlertFilter { all, unverified, critical, moderate, low }

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminAlertsScreen extends StatefulWidget {
  const AdminAlertsScreen({super.key});

  @override
  State<AdminAlertsScreen> createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends State<AdminAlertsScreen> {
  final _adminService = AdminService();
  _AlertFilter _filter = _AlertFilter.all;

  List<AlertModel> _applyFilter(List<AlertModel> alerts) => switch (_filter) {
    _AlertFilter.all => alerts,
    _AlertFilter.unverified =>
      alerts.where((a) => !a.verifiedByGovernment).toList(),
    _AlertFilter.critical =>
      alerts.where((a) => a.alertLevel == AlertLevel.red).toList(),
    _AlertFilter.moderate =>
      alerts.where((a) => a.alertLevel == AlertLevel.yellow).toList(),
    _AlertFilter.low =>
      alerts.where((a) => a.alertLevel == AlertLevel.green).toList(),
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
                      'Manage Alerts',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  StreamBuilder<int>(
                    stream: _adminService.streamAlertCount(),
                    builder: (context, snap) {
                      final count = snap.data ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE8E8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$count alerts',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE12626),
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
                    selected: _filter == _AlertFilter.all,
                    onTap: () => setState(() => _filter = _AlertFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    label: 'Unverified',
                    selected: _filter == _AlertFilter.unverified,
                    onTap: () =>
                        setState(() => _filter = _AlertFilter.unverified),
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    label: '🔴 Critical',
                    selected: _filter == _AlertFilter.critical,
                    onTap: () =>
                        setState(() => _filter = _AlertFilter.critical),
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    label: '🟡 Moderate',
                    selected: _filter == _AlertFilter.moderate,
                    onTap: () =>
                        setState(() => _filter = _AlertFilter.moderate),
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    label: '🟢 Low',
                    selected: _filter == _AlertFilter.low,
                    onTap: () => setState(() => _filter = _AlertFilter.low),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── List ──────────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<AlertModel>>(
                stream: _adminService.streamAllAlerts(),
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
                              Icons.crisis_alert_rounded,
                              size: 48,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No alerts found',
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
                      child: _AlertCard(
                        alert: filtered[i],
                        adminService: _adminService,
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

// ── Alert card ────────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  final AdminService adminService;

  const _AlertCard({required this.alert, required this.adminService});

  static Color _dotColor(AlertLevel level) => switch (level) {
    AlertLevel.red => const Color(0xFFBC1B1B),
    AlertLevel.yellow => const Color(0xFFD7AA11),
    AlertLevel.green => const Color(0xFF2E9F5D),
  };

  static IconData _iconFor(AlertModel alert) {
    final t = alert.title.toLowerCase();
    if (t.contains('flood')) return Icons.flood_outlined;
    if (t.contains('accident')) return Icons.car_crash_outlined;
    if (t.contains('fire')) return Icons.local_fire_department_outlined;
    if (t.contains('medical')) return Icons.medical_services_outlined;
    if (t.contains('quake')) return Icons.landscape_outlined;
    return Icons.crisis_alert_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dotColor = _dotColor(alert.alertLevel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: location + dot
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 13,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  'Lat ${alert.geoLocation.latitude.toStringAsFixed(4)}, '
                  'Lng ${alert.geoLocation.longitude.toStringAsFixed(4)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Icon + title + description + actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF2F2F2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconFor(alert),
                  color: const Color(0xFFE12626),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 15,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _timeAgo(alert.createdAt),
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        if (alert.verifiedByGovernment) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF2E9F5D,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              '✓ Verified',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E9F5D),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Action column
              Column(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: Icon(
                      alert.verifiedByGovernment
                          ? Icons.unpublished_outlined
                          : Icons.check_circle_outline_rounded,
                      size: 22,
                      color: alert.verifiedByGovernment
                          ? const Color(0xFF2E9F5D)
                          : colorScheme.onSurfaceVariant,
                    ),
                    tooltip: alert.verifiedByGovernment ? 'Unverify' : 'Verify',
                    onPressed: () async {
                      if (alert.verifiedByGovernment) {
                        await adminService.unverifyAlert(alert.id);
                      } else {
                        await adminService.verifyAlert(alert.id);
                      }
                    },
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 22,
                      color: Color(0xFFE12626),
                    ),
                    tooltip: 'Delete',
                    onPressed: () async {
                      final ok = await _confirmDelete(
                        context,
                        'Delete "${alert.title}"? This cannot be undone.',
                      );
                      if (ok) await adminService.deleteAlert(alert.id);
                    },
                  ),
                ],
              ),
            ],
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
