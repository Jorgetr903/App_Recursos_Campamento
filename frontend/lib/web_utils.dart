// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

void openUrlInNewTab(String url) {
  js.context.callMethod('openPdfUrl', [url]);
}