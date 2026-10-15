import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

/// A plain break timer. It blocks nothing; it is a prompt to stand up and rest.
class BreakScreen extends StatefulWidget {
  const BreakScreen({super.key, required this.minutes});

  final int minutes;

  @override
  State<BreakScreen> createState() => _BreakScreenState();
}

class _BreakScreenState extends State<BreakScreen> {
  late final DateTime _end = DateTime.now().add(Duration(minutes: widget.minutes));
  Timer? _timer;
  bool _over = false;

  Duration get _remaining {
    final left = _end.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining == Duration.zero && !_over) {
        _over = true;
        _timer?.cancel();
        HapticFeedback.mediumImpact();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final total = Duration(minutes: widget.minutes);
    final remaining = _remaining;
    final progress = (remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Break')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            SizedBox(
              width: 220,
              height: 220,
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
                  Text(
                    _over ? 'Done' : _format(remaining),
                    style: text.displayMedium?.copyWith(fontWeight: FontWeight.w300),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _over
                  ? 'Break over. Ready when you are.'
                  : 'Stand up, stretch, drink some water.',
              style: text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.go('/home'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Back to focus'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
