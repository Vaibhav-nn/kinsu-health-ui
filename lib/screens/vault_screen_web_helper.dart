// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class WebPdfViewerHelper {
  static final Set<String> _registeredViews = {};

  static void registerPdfViewer(String viewId, String pdfUrl) {
    if (_registeredViews.contains(viewId)) {
      return; // Already registered
    }

    try {
      ui_web.platformViewRegistry.registerViewFactory(
        viewId,
        (int id) {
          final iframe = html.IFrameElement()
            ..src = pdfUrl
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..allowFullscreen = true
            // Sandbox limits script execution inside embedded PDFs.
            // allow-same-origin is required so the browser can load the blob URL.
            ..setAttribute('sandbox', 'allow-same-origin allow-scripts');
          
          return iframe;
        },
      );
      _registeredViews.add(viewId);
    } catch (e) {
      print('Failed to register PDF viewer: $e');
    }
  }
}

/// Downloads a file in the browser
void downloadFileOnWeb(String url, String filename) {
  final anchor = html.AnchorElement(href: url)
    ..target = 'blank'
    ..download = filename;
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
