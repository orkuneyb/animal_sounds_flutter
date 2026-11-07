import 'package:animal_sounds_flutter/providers/purchase_provider.dart';
import 'package:animal_sounds_flutter/services/ad_service.dart';
import 'package:animal_sounds_flutter/widgets/banner_ad_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const adsChannel = MethodChannel('plugins.flutter.io/google_mobile_ads');

  tearDown(() {
    AdService().resetEntitlementForTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(adsChannel, null);
  });

  testWidgets('renders nothing and never talks to the ads SDK when ads are removed',
      (tester) async {
    final sdkCalls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(adsChannel, (call) async {
      sdkCalls.add(call.method);
      return null;
    });

    SharedPreferences.setMockInitialValues({'ads_removed': true});
    final provider =
        PurchaseProvider(prefs: await SharedPreferences.getInstance());

    await tester.pumpWidget(
      ChangeNotifierProvider<PurchaseProvider>.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: BannerAdWidget())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(AdWidget), findsNothing);
    expect(sdkCalls, isEmpty, reason: 'no ad request may leave the app');
    expect(tester.takeException(), isNull);
  });
}
