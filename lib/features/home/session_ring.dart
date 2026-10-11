import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// The timer ring. It owns the one-second ticker, so only this small widget
/// redraws each second, and only while a session is running.
class SessionRing extends StatefulWidget {
  const SessionRing({
    super.key,
    required this.start,
    required this.end,
    required this.idle,
    required this.onFinished,
  });

  /// Start and end of the running session. Null when none is running.
  final DateTime? start;
  final DateTime? end;

  /// Length shown when no session is running (the chosen duration).
  final Duration idle;

  /// Called once, when a running session reaches its end.
  final VoidCallback onFinished;

  @override
  State<SessionRing> createState() => _SessionRingState();
}

class _SessionRingState extends State<SessionRing> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(SessionRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.end != widget.end) _sync();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _running {
    final end = widget.end;
    return end != null && end.isAfter(DateTime.now());
  }

  void _sync() {
    _timer?.cancel();
    _timer = null;
    if (!_running) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_running) {
        setState(() {});
        return;
      }
      _timer?.cancel();
      _timer = null;
      setState(() {});
      widget.onFinished();
    });
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final running = _running;
    final end = widget.end;
    final start = widget.start;

    final remaining = running ? end!.difference(DateTime.now()) : Duration.zero;
    // The real length of the running session, not the chip that is selected.
    final total = running && start != null ? end!.difference(start) : widget.idle;
    final progress = running && total.inSeconds > 0
        ? (remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0)
        : 1.0;
    final shown = _format(running ? remaining : widget.idle);

    return Center(
      child: SizedBox(
        width: 240,
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 10,
                color: stillTeal,
                backgroundColor: context.line,
              ),
            ),
            Semantics(
              label: running ? 'Time left $shown' : 'Session length $shown',
              excludeSemantics: true,
              child: Text(
                shown,
                style: text.displayMedium?.copyWith(fontWeight: FontWeight.w300),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
