/// The multipart filename to send for a picked file.
///
/// This is not cosmetic. Dio derives the part's `Content-Type` from the
/// filename — `contentType ?? lookupMediaType(filename) ?? application/
/// octet-stream` — and never from the bytes. Every upload endpoint on the API
/// then checks `IFormFile.ContentType` against an allowlist of `image/jpeg`,
/// `image/png` (and `application/pdf` for KYC documents) and answers 400
/// "File must be JPG, PNG, or PDF" for anything else.
///
/// So an unrecognised extension is not a cosmetic problem: the bytes are
/// perfectly good JPEG and the server still refuses them, because the name
/// made them `application/octet-stream`.
///
/// `image_picker` names its temp copy after the source, which is exactly what
/// cannot be trusted: on iOS a camera roll original is `IMG_0042.HEIC`, and a
/// file resolved from an Android `content://` URI can arrive with no extension
/// at all. The product-image upload has always passed a fixed `image.jpg` and
/// has a clean record for it (57 uploads, 57 × 200); the paths that passed the
/// picked name through are the ones that broke.
///
/// IMPORTANT: an unknown extension is treated as JPEG, because every caller
/// picks through `ImagePicker` with `imageQuality` set, and that re-encodes to
/// JPEG whatever the source was. A caller that picks WITHOUT `imageQuality`
/// can hand over untouched HEIC bytes, and this would then label them `.jpg`
/// and have the server store a mislabelled object. Keep `imageQuality` set, or
/// convert before calling.
String uploadFilename(String path) {
  // Only the last segment can carry the extension. Looking at the whole path
  // would read `/tmp/v1.2/photo` as a `.2/photo` file.
  final separator = path.lastIndexOf(RegExp(r'[/\\]'));
  final name = separator == -1 ? path : path.substring(separator + 1);

  final dot = name.lastIndexOf('.');
  final extension = dot == -1 ? '' : name.substring(dot).toLowerCase();
  return switch (extension) {
    '.png' => 'upload.png',
    '.pdf' => 'upload.pdf',
    _ => 'upload.jpg',
  };
}
