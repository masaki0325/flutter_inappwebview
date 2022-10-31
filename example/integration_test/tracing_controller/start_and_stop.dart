import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';

import '../constants.dart';

void startAndStop() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
        ].contains(defaultTargetPlatform);

  testWidgets('start and stop', (WidgetTester tester) async {
    final Completer<void> pageLoaded = Completer<void>();

    final tracingAvailable = await WebViewFeature.isFeatureSupported(
        WebViewFeature.TRACING_CONTROLLER_BASIC_USAGE);

    if (!tracingAvailable) {
      return;
    }

    final tracingController = TracingController.instance();
    expect(await tracingController.isTracing(), false);
    await tracingController.start(
        settings: TracingSettings(
            tracingMode: TracingMode.RECORD_CONTINUOUSLY,
            categories: [
          TracingCategory.CATEGORIES_ANDROID_WEBVIEW,
          "blink*"
        ]));
    expect(await tracingController.isTracing(), true);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: InAppWebView(
          key: GlobalKey(),
          initialUrlRequest: URLRequest(url: TEST_CROSS_PLATFORM_URL_1),
          onLoadStop: (controller, url) {
            if (!pageLoaded.isCompleted) {
              pageLoaded.complete();
            }
          },
        ),
      ),
    );

    await pageLoaded.future;

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String traceFilePath = '${appDocDir.path}${Platform.pathSeparator}trace.json';
    expect(
        await tracingController.stop(filePath: traceFilePath), true);
    expect(await tracingController.isTracing(), false);
  }, skip: shouldSkip);
}