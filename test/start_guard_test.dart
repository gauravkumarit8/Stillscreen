import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/blocking/blocking_engine.dart';
import 'package:focus/core/installed_apps.dart';
import 'package:focus/core/start_guard.dart';
import 'package:focus/core/support_service.dart';

InstalledApp app(String p) => InstalledApp(package: p, label: p);

void main() {
  group('evaluateStart', () {
    test('blocking off comes first, even with apps chosen', () {
      expect(evaluateStart(permissionGranted: false, chosenInstalledApps: 5),
          StartCheck.needsPermission);
    });
    test('blocking off and no apps', () {
      expect(evaluateStart(permissionGranted: false, chosenInstalledApps: 0),
          StartCheck.needsPermission);
    });
    test('blocking on but nothing chosen', () {
      expect(evaluateStart(permissionGranted: true, chosenInstalledApps: 0),
          StartCheck.needsApps);
    });
    test('blocking on and apps chosen', () {
      expect(evaluateStart(permissionGranted: true, chosenInstalledApps: 1),
          StartCheck.ready);
    });
  });

  group('installedCount', () {
    final installed = [app('a'), app('b'), app('c')];

    test('ignores apps that are no longer installed', () {
      expect(installedCount(installed, {'a', 'gone', 'c'}), 2);
    });
    test('nothing selected', () => expect(installedCount(installed, {}), 0));
    test('uses the saved list while the app list is still loading', () {
      expect(installedCount(null, {'a', 'b'}), 2);
    });
  });

  test('feedback email body carries the version and phone', () {
    final body = feedbackBody(const AppInfo(
      versionName: '0.1.1',
      versionCode: 2,
      device: 'Acme X1',
      androidVersion: '14 (API 34)',
    ));
    expect(body, contains('App: 0.1.1 (2)'));
    expect(body, contains('Phone: Acme X1'));
    expect(body, contains('Android: 14 (API 34)'));
    expect(body, startsWith('What happened?'));
  });

  group('evaluateStart with a stopped service', () {
    test('permission on but service stopped is its own case', () {
      expect(
        evaluateStart(
          permissionGranted: true,
          chosenInstalledApps: 3,
          serviceConnected: false,
        ),
        StartCheck.serviceStopped,
      );
    });

    test('missing permission is reported before a stopped service', () {
      expect(
        evaluateStart(
          permissionGranted: false,
          chosenInstalledApps: 3,
          serviceConnected: false,
        ),
        StartCheck.needsPermission,
      );
    });

    test('a stopped service is reported before missing apps', () {
      expect(
        evaluateStart(
          permissionGranted: true,
          chosenInstalledApps: 0,
          serviceConnected: false,
        ),
        StartCheck.serviceStopped,
      );
    });

    test('a running service changes nothing', () {
      expect(
        evaluateStart(
          permissionGranted: true,
          chosenInstalledApps: 2,
          serviceConnected: true,
        ),
        StartCheck.ready,
      );
    });
  });
}
