import 'package:flutter/material.dart';

/// Keeps the whole app usable on every screen.
///
/// * On tablets, foldables and landscape phones the content never gets wider
///   than [maxContentWidth], so cards and charts do not stretch awkwardly.
/// * The user's font-size setting is respected, but only up to
///   [maxTextScale], so fixed-size parts (timer ring, chips, charts) cannot
///   break at extreme settings. Screens also scroll, so nothing is cut off.
class ResponsiveFrame extends StatelessWidget {
  const ResponsiveFrame({super.key, required this.child});

  final Widget child;

  static const double maxContentWidth = 600;
  static const double maxTextScale = 1.6;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: media.textScaler.clamp(maxScaleFactor: maxTextScale),
      ),
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}
