import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_icons.dart';

class AppIcon extends ConsumerWidget {
  const AppIcon({super.key, required this.package});

  final String package;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = ref.watch(appIconProvider(package)).valueOrNull;
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );

    return SizedBox(
      width: 40,
      height: 40,
      child: icon == null
          ? placeholder
          : Image.memory(icon, width: 40, height: 40, gaplessPlayback: true),
    );
  }
}
