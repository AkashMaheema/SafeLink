import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/router.dart';
import '../../models/alert_model.dart';
import '../../models/comment_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/interaction_service.dart';
import '../../services/storage_service.dart';

class AlertDetailScreen extends StatefulWidget {
  final AlertModel alert;

  const AlertDetailScreen({super.key, required this.alert});

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  // Single instance — not recreated on every rebuild
  final _interactionService = InteractionService();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
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
                      'Alerts',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.notifications);
                    },
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _VerifiedBadge(
                      alert: widget.alert,
                      interactionService: _interactionService,
                    ),
                    const SizedBox(height: 20),
                    _ReactionRow(
                      alert: widget.alert,
                      interactionService: _interactionService,
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader(title: 'Description'),
                    const SizedBox(height: 8),
                    _DescriptionCard(alert: widget.alert),
                    const SizedBox(height: 24),
                    _ProofSection(alert: widget.alert),
                    const SizedBox(height: 28),
                    _TipsSection(alert: widget.alert),
                    const SizedBox(height: 32),
                    _SectionHeader(title: 'Comments'),
                    const SizedBox(height: 12),
                    _CommentsSection(
                      alert: widget.alert,
                      interactionService: _interactionService,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Verified badge + vote-driven progress bar ─────────────────────────────────

// Maps emergency title keywords → icon + color
IconData _iconForAlert(AlertModel alert) {
  final t = alert.title.toLowerCase();
  if (t.contains('accident')) return Icons.car_crash_rounded;
  if (t.contains('fire')) return Icons.local_fire_department_rounded;
  if (t.contains('medical')) return Icons.medical_services_rounded;
  if (t.contains('flood')) return Icons.water_damage_rounded;
  if (t.contains('quake')) return Icons.terrain_rounded;
  if (t.contains('robbery')) return Icons.lock_open_rounded;
  if (t.contains('assault')) return Icons.report_problem_rounded;
  return Icons.crisis_alert_rounded;
}

class _VerifiedBadge extends StatelessWidget {
  final AlertModel alert;
  final InteractionService interactionService;

  const _VerifiedBadge({required this.alert, required this.interactionService});

  @override
  Widget build(BuildContext context) {
    final isVerified = alert.verifiedByGovernment;

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFFE12626),
            shape: BoxShape.circle,
          ),
          child: Icon(_iconForAlert(alert), color: Colors.white, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          isVerified ? 'Verified' : 'Unverified',
          style: TextStyle(
            color: isVerified ? const Color(0xFFE12626) : Colors.orange,
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),

        // Vote-driven colour bar
        StreamBuilder<VoteSummary>(
          stream: interactionService.streamVotes(alert.id),
          builder: (context, snap) {
            final ratio = snap.data?.positiveRatio ?? 0.5;
            return _VoteBar(ratio: ratio);
          },
        ),
      ],
    );
  }
}

/// Animated bar that goes red (all downvotes) → yellow → green (all upvotes).
class _VoteBar extends StatelessWidget {
  final double ratio; // 0.0 – 1.0

  const _VoteBar({required this.ratio});

  @override
  Widget build(BuildContext context) {
    // Interpolate red → yellow → green
    final Color barColor;
    if (ratio < 0.5) {
      barColor = Color.lerp(
        const Color(0xFFE12626),
        const Color(0xFFD7AA11),
        ratio * 2,
      )!;
    } else {
      barColor = Color.lerp(
        const Color(0xFFD7AA11),
        const Color(0xFF2E9F5D),
        (ratio - 0.5) * 2,
      )!;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              height: 6,
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              height: 6,
              width: constraints.maxWidth * ratio,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Reaction row ──────────────────────────────────────────────────────────────

class _ReactionRow extends StatelessWidget {
  final AlertModel alert;
  final InteractionService interactionService;

  const _ReactionRow({required this.alert, required this.interactionService});

  @override
  Widget build(BuildContext context) {
    final uid =
        context.select<AuthProvider, String?>((auth) => auth.userModel?.uid) ??
        '';

    return StreamBuilder<String?>(
      stream: uid.isNotEmpty
          ? interactionService.streamMyVote(alert.id, uid)
          : const Stream.empty(),
      builder: (context, myVoteSnap) {
        final myVote = myVoteSnap.data; // null = no vote or still loading

        return StreamBuilder<VoteSummary>(
          stream: interactionService.streamVotes(alert.id),
          builder: (context, summarySnap) {
            final summary =
                summarySnap.data ?? const VoteSummary(upvotes: 0, downvotes: 0);

            final upActive = myVote == 'up';
            final downActive = myVote == 'down';

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Upvote — turns green when active
                _VoteButton(
                  icon: Icons.thumb_up_outlined,
                  activeIcon: Icons.thumb_up_rounded,
                  count: summary.upvotes,
                  isActive: upActive,
                  activeColor: const Color(0xFF2E9F5D),
                  onTap: uid.isEmpty
                      ? null
                      : () => interactionService.castVote(
                          alertId: alert.id,
                          uid: uid,
                          vote: 'up',
                        ),
                ),
                const SizedBox(width: 28),

                // Downvote — turns red when active
                _VoteButton(
                  icon: Icons.thumb_down_outlined,
                  activeIcon: Icons.thumb_down_rounded,
                  count: summary.downvotes,
                  isActive: downActive,
                  activeColor: const Color(0xFFE12626),
                  onTap: uid.isEmpty
                      ? null
                      : () => interactionService.castVote(
                          alertId: alert.id,
                          uid: uid,
                          vote: 'down',
                        ),
                ),
                const SizedBox(width: 28),

                // Comment
                _IconActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: () async => _showCommentSheet(context, uid),
                ),
                const SizedBox(width: 28),

                // Share
                _IconActionButton(
                  icon: Icons.reply_rounded,
                  mirrorHorizontal: true,
                  onTap: () async {
                    await Share.share(
                      '🚨 ${alert.title}\n\n${alert.description}\n\nShared via SafeLink',
                      subject: 'Emergency Alert: ${alert.title}',
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCommentSheet(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentInputSheet(
        alert: alert,
        uid: uid,
        interactionService: interactionService,
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int count;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onTap;

  const _VoteButton({
    required this.icon,
    required this.activeIcon,
    required this.count,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isActive ? activeColor : colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                size: 26,
                color: color,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(height: 2),
              Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final Future<void> Function()? onTap;
  final bool mirrorHorizontal;

  const _IconActionButton({
    required this.icon,
    this.onTap,
    this.mirrorHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget iconWidget = Icon(
      icon,
      size: 26,
      color: colorScheme.onSurfaceVariant,
    );

    if (mirrorHorizontal) {
      iconWidget = Transform.flip(flipX: true, child: iconWidget);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null ? null : () => onTap!(),
      child: Padding(padding: const EdgeInsets.all(6), child: iconWidget),
    );
  }
}

// ── Comment input bottom sheet ────────────────────────────────────────────────

class _CommentInputSheet extends StatefulWidget {
  final AlertModel alert;
  final String uid;
  final InteractionService interactionService;

  const _CommentInputSheet({
    required this.alert,
    required this.uid,
    required this.interactionService,
  });

  @override
  State<_CommentInputSheet> createState() => _CommentInputSheetState();
}

class _CommentInputSheetState extends State<_CommentInputSheet> {
  final _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.uid.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final displayName =
          context.read<AuthProvider>().userModel?.displayName ?? 'Anonymous';
      await widget.interactionService.addComment(
        alertId: widget.alert.id,
        uid: widget.uid,
        displayName: displayName,
        text: text,
      );
      _controller.clear();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      // ignore errors silently for now
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add a comment',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 4,
            minLines: 2,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontFamily: 'Poppins',
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Share what you know about this alert…',
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: _isSending ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE12626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Post Comment',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Comments section ──────────────────────────────────────────────────────────

class _CommentsSection extends StatelessWidget {
  final AlertModel alert;
  final InteractionService interactionService;

  const _CommentsSection({
    required this.alert,
    required this.interactionService,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<CommentModel>>(
      stream: interactionService.streamComments(alert.id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final comments = snap.data ?? [];

        if (comments.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'No comments yet. Be the first to share what you know.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'Poppins',
                fontSize: 13,
              ),
            ),
          );
        }

        return Column(
          children: comments
              .map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CommentTile(comment: c),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFFFE8E8),
            child: Text(
              comment.displayName.isNotEmpty
                  ? comment.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Color(0xFFE12626),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.displayName,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _timeAgo(comment.createdAt),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontFamily: 'Poppins',
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontFamily: 'Poppins',
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ── Description card ──────────────────────────────────────────────────────────

class _DescriptionCard extends StatelessWidget {
  final AlertModel alert;

  const _DescriptionCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locationLabel = _locationLabel(alert);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Spacer(),
            Icon(
              Icons.location_on_outlined,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              locationLabel,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          alert.description,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  static String _locationLabel(AlertModel alert) {
    if (alert.id.startsWith('preview-')) return 'Kothrud, Pune, 411038';
    return 'Lat ${alert.geoLocation.latitude.toStringAsFixed(4)}, '
        'Lng ${alert.geoLocation.longitude.toStringAsFixed(4)}';
  }
}

// ── Proof section (images from Firestore proofs subcollection) ───────────────

class _ProofSection extends StatelessWidget {
  final AlertModel alert;

  const _ProofSection({required this.alert});

  @override
  Widget build(BuildContext context) {
    final proofService = ProofStorageService();

    return StreamBuilder<List<ProofDocument>>(
      stream: proofService.streamProofs(alert.id),
      builder: (context, snap) {
        // Still loading — show nothing (avoids flicker)
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final proofs = snap.data ?? [];
        if (proofs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const _SectionHeader(title: 'Images / Proof'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: proofs
                  .map((proof) => _ProofThumbnail(proof: proof))
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

class _ProofThumbnail extends StatelessWidget {
  final ProofDocument proof;

  const _ProofThumbnail({required this.proof});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = (MediaQuery.of(context).size.width - 40 - 16) / 3;

    return GestureDetector(
      onTap: () => _showFullScreen(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: size,
          height: size,
          child: proof.base64.isNotEmpty
              ? Image.memory(
                  proof.bytes,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(colorScheme),
                )
              : _placeholder(colorScheme),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) => Container(
    color: cs.surfaceContainerHighest,
    child: Icon(
      Icons.broken_image_outlined,
      color: cs.onSurfaceVariant,
      size: 28,
    ),
  );

  void _showFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _FullScreenImage(proof: proof)),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final ProofDocument proof;

  const _FullScreenImage({required this.proof});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          proof.fileName,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.memory(proof.bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

// ── Tips section ──────────────────────────────────────────────────────────────

class _TipsSection extends StatelessWidget {
  final AlertModel alert;

  const _TipsSection({required this.alert});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tips = _tipsFor(alert);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: Color(0xFFE12626),
            ),
            const SizedBox(width: 6),
            const Text(
              'Tips that might be helpful',
              style: TextStyle(
                color: Color(0xFFE12626),
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          tips.title,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tips.intro,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        ...tips.steps.asMap().entries.map((entry) {
          final i = entry.key + 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$i. ',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static _TipContent _tipsFor(AlertModel alert) {
    final title = alert.title.toLowerCase();
    if (title.contains('accident')) {
      return const _TipContent(
        title: 'If you are in an accident',
        intro:
            'Stay Calm & Check for Injuries – Assess yourself and passengers for injuries.',
        steps: [
          'Move to Safety (If Possible) – If the vehicle is drivable, move it to the side of the road. If not, turn on hazard lights.',
          'Call Emergency Services – Dial 112 or your local emergency number immediately.',
          'Do Not Move Injured Persons – Unless there is immediate danger (fire, traffic), avoid moving injured people.',
          'Document the Scene – Take photos of the vehicles, road, and any injuries if it is safe to do so.',
        ],
      );
    }
    if (title.contains('flood')) {
      return const _TipContent(
        title: 'If you are in a flood',
        intro:
            'Move to higher ground immediately and avoid walking or driving through floodwaters.',
        steps: [
          'Evacuate Early – Do not wait for floodwaters to reach your home.',
          'Avoid Floodwater – Even 15 cm of fast-moving water can knock you down.',
          'Turn Off Utilities – Switch off electricity at the breaker if safe to do so.',
          'Contact Emergency Services – Call 112 and follow official instructions.',
        ],
      );
    }
    if (title.contains('fire')) {
      return const _TipContent(
        title: 'If there is a fire nearby',
        intro: 'Evacuate immediately and alert others around you.',
        steps: [
          'Get Out Fast – Leave the building or area without collecting belongings.',
          'Stay Low – Crawl under smoke to find cleaner air near the floor.',
          'Close Doors – Closing doors slows the spread of fire and smoke.',
          'Call 101 – Report the fire and your location to emergency services.',
        ],
      );
    }
    return const _TipContent(
      title: 'Stay safe during an emergency',
      intro: 'Keep calm and follow official guidance from emergency services.',
      steps: [
        'Move away from the danger zone if it is safe to do so.',
        'Call 112 to report the emergency and request assistance.',
        'Stay informed by monitoring official news and alerts.',
        'Help others around you if you can do so without putting yourself at risk.',
      ],
    );
  }
}

class _TipContent {
  final String title;
  final String intro;
  final List<String> steps;

  const _TipContent({
    required this.title,
    required this.intro,
    required this.steps,
  });
}
