class UploadCanceledException implements Exception {
  const UploadCanceledException();

  @override
  String toString() => 'UploadCanceledException: upload was canceled by user';
}
