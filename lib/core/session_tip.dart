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
    '1. Open recent apps, long-press the Stillscreen card, and tap the lock icon.\n'
    '2. Do not swipe Stillscreen away while a session is running.\n'
    '3. In Settings, allow Autostart and set battery to No restrictions.\n\n'
    'If blocking ever stops, Stillscreen will tell you on the home screen.';
