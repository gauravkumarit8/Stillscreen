/// Session lengths, in minutes.
const sessionPresets = [25, 50, 90];
const minSessionMinutes = 5;
const maxSessionMinutes = 120;
const defaultSessionMinutes = 25;

bool isPresetLength(int minutes) => sessionPresets.contains(minutes);

/// Keeps a saved or chosen length inside the allowed range, in steps of five.
int normalizeSessionMinutes(int? minutes) {
  if (minutes == null) return defaultSessionMinutes;
  final stepped = (minutes / 5).round() * 5;
  return stepped.clamp(minSessionMinutes, maxSessionMinutes);
}
