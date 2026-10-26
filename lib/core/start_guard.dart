/// What has to be true before a focus session can really block anything.
enum StartCheck { ready, needsPermission, serviceStopped, needsApps }

StartCheck evaluateStart({
  required bool permissionGranted,
  required int chosenInstalledApps,
  bool serviceConnected = true,
}) {
  if (!permissionGranted) return StartCheck.needsPermission;
  // The permission can show as on while the phone has stopped the service.
  if (!serviceConnected) return StartCheck.serviceStopped;
  if (chosenInstalledApps == 0) return StartCheck.needsApps;
  return StartCheck.ready;
}
