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
            ..allowFullscreen = true;
          
          return iframe;
        },
      );
      _registeredViews.add(viewId);
    } catch (e) {
      print('Failed to register PDF viewer: $e');
    }
  }
}
