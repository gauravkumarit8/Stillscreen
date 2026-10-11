/// What has to be true before a focus session can really block anything.
enum StartCheck { ready, needsPermission, needsApps }

StartCheck evaluateStart({
  required bool permissionGranted,
  required int chosenInstalledApps,
}) {
  if (!permissionGranted) return StartCheck.needsPermission;
  if (chosenInstalledApps == 0) return StartCheck.needsApps;
  return StartCheck.ready;
}
