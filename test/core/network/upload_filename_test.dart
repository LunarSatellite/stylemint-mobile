import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/upload_filename.dart';

/// The filename decides the multipart media type, and the media type decides
/// whether the API's allowlist accepts the upload at all. A name that produces
/// `application/octet-stream` is refused with 400 "File must be JPG, PNG, or
/// PDF" no matter how good the bytes are — so these are wire expectations, not
/// cosmetics.
void main() {
  group('uploadFilename', () {
    test('keeps JPEG for the names image_picker actually produces', () {
      expect(uploadFilename('/tmp/image_picker_A1B2.jpg'), 'upload.jpg');
      expect(uploadFilename('/tmp/scaled_IMG_0042.jpeg'), 'upload.jpg');
      expect(uploadFilename(r'C:\Users\x\AppData\Local\Temp\pick.JPG'),
          'upload.jpg');
    });

    test('keeps PNG and PDF, which the KYC endpoint also accepts', () {
      expect(uploadFilename('/tmp/scan.png'), 'upload.png');
      expect(uploadFilename('/tmp/SCAN.PNG'), 'upload.png');
      expect(uploadFilename('/tmp/licence.pdf'), 'upload.pdf');
    });

    test('falls back to JPEG for the names that were being refused', () {
      // An iOS camera-roll original, and an Android file resolved from a
      // content:// URI with no extension at all. Both reached the server as
      // octet-stream when the picked name was passed through; both are JPEG
      // by the time we see them, because every caller sets imageQuality.
      expect(uploadFilename('/var/mobile/.../IMG_0042.HEIC'), 'upload.jpg');
      expect(uploadFilename('/data/user/0/cache/1000000031'), 'upload.jpg');
      expect(uploadFilename('/tmp/no-extension-here'), 'upload.jpg');
    });

    test('is not fooled by a dot in a directory name', () {
      expect(uploadFilename('/tmp/v1.2/photo'), 'upload.jpg');
      expect(uploadFilename('/tmp/v1.2/photo.png'), 'upload.png');
    });
  });
}
