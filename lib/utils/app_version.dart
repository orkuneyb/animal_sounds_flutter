import 'package:package_info_plus/package_info_plus.dart';

/// The installed version as shown to parents, e.g. `1.3.0+10`.
Future<String> appVersionLabel() async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version}+${info.buildNumber}';
}
