import 'package:url_launcher/url_launcher.dart';

/// Opens a phone call or a WhatsApp chat with a number the buyer consented
/// to share. Only ever handed a consented number (bank leads); bookings never
/// carry buyer contact details at all.
abstract class ServiceContactLauncher {
  const ServiceContactLauncher();

  Future<bool> open(Uri uri);
}

class UrlServiceContactLauncher extends ServiceContactLauncher {
  const UrlServiceContactLauncher();

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}

/// The digits of [phone], keeping a leading `+`.
String cleanPhone(String phone) {
  final trimmed = phone.trim();
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  return trimmed.startsWith('+') ? '+$digits' : digits;
}

/// `tel:+9779841000000`.
Uri phoneCallUri(String phone) => Uri(scheme: 'tel', path: cleanPhone(phone));

/// `https://wa.me/9779841000000` — international digits without `+`. A
/// 10-digit Nepali mobile number without a country code gets 977.
Uri whatsAppUri(String phone) {
  var digits = cleanPhone(phone).replaceAll('+', '');
  if (digits.startsWith('00')) digits = digits.substring(2);
  if (digits.length == 10 && digits.startsWith('9')) digits = '977$digits';
  return Uri.parse('https://wa.me/$digits');
}

/// A number worth offering a call for: 7–15 digits (the contract's rule).
bool isCallablePhone(String? phone) {
  if (phone == null) return false;
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.length >= 7 && digits.length <= 15;
}
