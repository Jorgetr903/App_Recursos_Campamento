import 'dart:js_interop';

@JS('openPdfUrl')
external void openUrlInNewTab(String url);

@JS('downloadPdfUrl')
external void downloadUrl(String url, String filename);