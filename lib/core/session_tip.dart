import 'battery_guide.dart';

const sessionTipShownKey = 'session_tip_shown';

/// Phones from some brands stop blocking when Stillscreen is swiped away from
/// recent apps. A one-time tip when the first session starts says how to
/// prevent that, at the moment it matters.
bool shouldShowSessionTip({
  required String manufacturer,
  required bool alreadyShown,
}) =>
    !alreadyShown && needsPopupPermission(manufacturer);

const sessionTipText =
    'On your phone, swiping Stillscreen away from recent apps stops blocking.\n\n'
    'To keep blocking on:\n'
    '1. While a session runs, Stillscreen hides from recent apps so it cannot be '
    'swiped away by mistake. Open it from its icon.\n'
    '2. Before you start, you can also open recent apps, long-press the '
    'Stillscreen card, and tap the lock icon.\n'
    '3. Do not use Clear all or a cleaner app during a session.\n'
    '4. In Settings, allow Autostart and set battery to No restrictions.\n\n'
    'If blocking ever stops, Stillscreen will tell you on the home screen.';
