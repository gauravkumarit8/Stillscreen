import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/app_config.dart';

void main() {
  test('a build made by hand reads local', () {
    expect(buildNumber, 'local');
  });
}
