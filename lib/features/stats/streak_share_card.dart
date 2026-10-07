import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/share/share_text.dart';

const _tealOnDark = Color(0xFF62B5B0);

/// The image people share. Fixed at 270 x 480 logical pixels (9:16); it is
/// captured at 4x, giving a 1080 x 1920 picture that suits stories and chats.
class StreakShareCard extends StatelessWidget {
  const StreakShareCard({
    super.key,
    required this.streak,
    required this.weekMinutes,
    required this.totalMinutes,
  });

  static const width = 270.0;
  static const height = 480.0;

  final int streak;
  final int weekMinutes;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: deepWater,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stillscreen',
            style: TextStyle(
              color: mist,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          Center(
            child: Container(
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: mist, width: 8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$streak',
                    style: const TextStyle(
                      color: mist,
                      fontSize: 64,
                      fontWeight: FontWeight.w600,
                      height: 1.05,
                    ),
                  ),
                  const Text(
                    'day streak',
                    style: TextStyle(color: _tealOnDark, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(label: 'This week', value: formatMinutes(weekMinutes)),
              _Stat(label: 'All time', value: formatMinutes(totalMinutes)),
            ],
          ),
          const Spacer(),
          const Text(
            'Focus without the scroll.',
            style: TextStyle(color: _tealOnDark, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: mist,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: _tealOnDark, fontSize: 12)),
      ],
    );
  }
}
