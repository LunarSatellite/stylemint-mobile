import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// How many embedded players the reel feed may keep alive on this device.
///
/// Each embedded player is a WebView with its own renderer; on the 3.8 GB
/// test phone two of them already put the app at 280–460 MB. Phones under
/// 4.5 GB, phones that report themselves as low-RAM, and iPhones (which kill
/// memory-heavy apps early) keep two: the reel on screen and the next one.
/// Other Android phones also keep the previous reel ready.
Future<int> embedSlotCountForDevice() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return 2;
  try {
    final info = await DeviceInfoPlugin().androidInfo;
    if (info.isLowRamDevice || info.physicalRamSize < 4500) return 2;
    return 3;
  } on Exception {
    return 2;
  }
}
