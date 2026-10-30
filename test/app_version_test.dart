import 'package:animal_sounds_flutter/utils/app_version.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  test('appVersionLabel joins version and build number', () async {
    PackageInfo.setMockInitialValues(
      appName: 'Animal Sounds',
      packageName: 'com.devork.animalsounds',
      version: '1.3.0',
      buildNumber: '10',
      buildSignature: '',
    );

    expect(await appVersionLabel(), '1.3.0+10');
  });
}
