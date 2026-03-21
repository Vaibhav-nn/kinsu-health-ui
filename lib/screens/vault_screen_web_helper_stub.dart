class WebPdfViewerHelper {
  static void registerPdfViewer(String viewId, String pdfUrl) {
    // Stub for non-web platforms
    throw UnsupportedError('Web PDF viewer is not supported on this platform');
  }
}

/// Stub for downloading files on non-web platforms
void downloadFileOnWeb(String url, String filename) {
  // Stub - not used on non-web platforms
  throw UnsupportedError('Web download is not supported on this platform');
}
