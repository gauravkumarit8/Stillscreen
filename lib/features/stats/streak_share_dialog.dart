import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_config.dart';
import '../../core/session_log.dart';
import '../../core/share/share_service.dart';
import '../../core/share/share_text.dart';
import 'streak_share_card.dart';

Future<void> showStreakShareDialog(BuildContext context, FocusStats stats) {
  return showDialog<void>(
    context: context,
    builder: (_) => _StreakShareDialog(stats: stats),
  );
}

class _StreakShareDialog extends ConsumerStatefulWidget {
  const _StreakShareDialog({required this.stats});

  final FocusStats stats;

  @override
  ConsumerState<_StreakShareDialog> createState() => _StreakShareDialogState();
}

class _StreakShareDialogState extends ConsumerState<_StreakShareDialog> {
  final _boundaryKey = GlobalKey();
  bool _busy = false;

  int get _weekMinutes => widget.stats
      .lastDays(7)
      .fold(0, (sum, day) => sum + widget.stats.minutesOn(day));

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 4);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final caption = shareCaption(
        streak: widget.stats.currentStreak,
        totalMinutes: widget.stats.totalMinutes,
        link: storeLink,
      );
      await ref
          .read(shareServiceProvider)
          .shareImage(data!.buffer.asUint8List(), caption);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e is UnsupportedError
            ? 'Sharing works on Android only.'
            : 'Could not share. Please try again.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: FittedBox(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RepaintBoundary(
                    key: _boundaryKey,
                    child: StreakShareCard(
                      streak: widget.stats.currentStreak,
                      weekMinutes: _weekMinutes,
                      totalMinutes: widget.stats.totalMinutes,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _busy ? null : _share,
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: const Text('Share'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
