import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_packs.dart';
import '../../core/blocking/blocking_engine.dart';
import '../../core/installed_apps.dart';
import '../../core/pause.dart';
import '../../core/prefs.dart';
import '../../core/winddown.dart';

/// Which list of apps the picker edits.
enum AppListKind { focus, windDown, pause }

String _titleFor(AppListKind kind) => switch (kind) {
      AppListKind.focus => 'Apps to block',
      AppListKind.windDown => 'Work apps to pause',
      AppListKind.pause => 'Apps to pause',
    };

List<AppPack> _packsFor(AppListKind kind) => switch (kind) {
      AppListKind.focus => focusPacks,
      AppListKind.windDown => windDownPacks,
      AppListKind.pause => pausePacks,
    };

ProviderListenable<Set<String>> _sourceFor(AppListKind kind) => switch (kind) {
      AppListKind.focus => blockedAppsProvider,
      AppListKind.windDown => windDownAppsProvider,
      AppListKind.pause => pauseAppsProvider,
    };

Future<void> _toggle(WidgetRef ref, AppListKind kind, String package) {
  switch (kind) {
    case AppListKind.focus:
      return ref.read(blockedAppsProvider.notifier).toggle(package);
    case AppListKind.windDown:
      return ref.read(windDownAppsProvider.notifier).toggle(package);
    case AppListKind.pause:
      return ref.read(pauseAppsProvider.notifier).toggle(package);
  }
}

Future<void> _setMany(
  WidgetRef ref,
  AppListKind kind,
  Iterable<String> packages,
  bool selected,
) {
  switch (kind) {
    case AppListKind.focus:
      return ref
          .read(blockedAppsProvider.notifier)
          .setMany(packages, selected: selected);
    case AppListKind.windDown:
      return ref
          .read(windDownAppsProvider.notifier)
          .setMany(packages, selected: selected);
    case AppListKind.pause:
      return ref
          .read(pauseAppsProvider.notifier)
          .setMany(packages, selected: selected);
  }
}

/// Picker for installed apps, with search, select all and one-tap packs.
class AppsScreen extends ConsumerStatefulWidget {
  const AppsScreen({super.key, this.kind = AppListKind.focus});

  final AppListKind kind;

  @override
  ConsumerState<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends ConsumerState<AppsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final apps = ref.watch(installedAppsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(widget.kind)),
        actions: [
          IconButton(
            tooltip: 'Refresh app list',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(installedAppsProvider),
          ),
        ],
      ),
      body: apps.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Could not load your apps. Tap refresh to try again.'),
          ),
        ),
        data: _buildList,
      ),
    );
  }

  Widget _buildList(List<InstalledApp> all) {
    final selected = ref.watch(_sourceFor(widget.kind));
    final query = _query.trim().toLowerCase();

    final visible = query.isEmpty
        ? all
        : all.where((a) => a.label.toLowerCase().contains(query)).toList();
    final visiblePackages = visible.map((a) => a.package).toList();
    final selectedVisible = visiblePackages.where(selected.contains).length;
    final allSelected = visible.isNotEmpty && selectedVisible == visible.length;

    // Only show packs that have at least one installed app.
    final packs = <(AppPack, List<String>)>[
      for (final pack in _packsFor(widget.kind))
        (pack, all.where(pack.matches).map((a) => a.package).toList()),
    ].where((entry) => entry.$2.isNotEmpty).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search apps',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        if (packs.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: packs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (pack, packages) = packs[i];
                final packSelected = packages.every(selected.contains);
                return FilterChip(
                  avatar: Icon(pack.icon, size: 18),
                  label: Text('${pack.name} (${packages.length})'),
                  selected: packSelected,
                  onSelected: (_) =>
                      _setMany(ref, widget.kind, packages, !packSelected),
                );
              },
            ),
          ),
        CheckboxListTile(
          tristate: true,
          value: allSelected ? true : (selectedVisible == 0 ? false : null),
          onChanged: visible.isEmpty
              ? null
              : (_) => _setMany(ref, widget.kind, visiblePackages, !allSelected),
          title: Text(query.isEmpty
              ? 'Select all'
              : 'Select all matching "${_query.trim()}"'),
          subtitle: Text('$selectedVisible of ${visible.length} selected'),
        ),
        const Divider(height: 1),
        Expanded(
          child: visible.isEmpty
              ? const Center(child: Text('No apps match your search.'))
              : ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (_, i) => _AppTile(
                    key: ValueKey(visible[i].package),
                    app: visible[i],
                    kind: widget.kind,
                  ),
                ),
        ),
      ],
    );
  }
}

/// Watches only its own selection state, so ticking one app rebuilds one row
/// instead of the whole list.
class _AppTile extends ConsumerWidget {
  const _AppTile({super.key, required this.app, required this.kind});

  final InstalledApp app;
  final AppListKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected =
        ref.watch(_sourceFor(kind).select((s) => s.contains(app.package)));

    return CheckboxListTile(
      title: Text(app.label),
      value: isSelected,
      onChanged: (_) => _toggle(ref, kind, app.package),
    );
  }
}
