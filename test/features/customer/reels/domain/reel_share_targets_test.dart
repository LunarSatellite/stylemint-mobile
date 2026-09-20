import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/reel_share_targets.dart';

void main() {
  final link = Uri.parse('https://stylemint.voyageritnepal.com/reels/reel-1');
  const message =
      "Glow & go\n\nWatch sumendra's reel on StyleMint: "
      'https://stylemint.voyageritnepal.com/reels/reel-1';

  String decodedQuery(Uri uri, String key) => Uri.decodeComponent(
    uri.query
        .split('&')
        .firstWhere(
          (part) => part.startsWith('$key='),
        )
        .substring(key.length + 1),
  );

  test('each target opens its own share link with the StyleMint message', () {
    final whatsApp = ReelShareTarget.whatsApp.uri(link: link, message: message);
    expect(
      '${whatsApp.scheme}://${whatsApp.host}${whatsApp.path}',
      'https://wa.me/',
    );
    expect(decodedQuery(whatsApp, 'text'), message);

    final viber = ReelShareTarget.viber.uri(link: link, message: message);
    expect(viber.scheme, 'viber');
    expect(viber.host, 'forward');
    expect(decodedQuery(viber, 'text'), message);

    final sms = ReelShareTarget.messages.uri(link: link, message: message);
    expect(sms.scheme, 'sms');
    expect(decodedQuery(sms, 'body'), message);
  });

  test('Facebook shares the link itself, which it previews', () {
    final facebook = ReelShareTarget.facebook.uri(link: link, message: message);
    expect(facebook.host, 'www.facebook.com');
    expect(facebook.path, '/sharer/sharer.php');
    expect(decodedQuery(facebook, 'u'), link.toString());
  });

  test('spaces are percent-encoded, not turned into plus signs', () {
    final whatsApp = ReelShareTarget.whatsApp.uri(link: link, message: message);
    expect(whatsApp.toString(), isNot(contains('+')));
    expect(whatsApp.toString(), contains('%20'));
    expect(whatsApp.toString(), contains('%26'), reason: 'the & in the hook');
  });

  test(
    'WhatsApp and Viber wait for their apps, checked by their own scheme',
    () {
      expect(
        [
          for (final t in ReelShareTarget.values)
            if (t.needsInstalledApp) t,
        ],
        [ReelShareTarget.whatsApp, ReelShareTarget.viber],
      );
      expect(ReelShareTarget.whatsApp.installedProbe?.scheme, 'whatsapp');
      expect(ReelShareTarget.viber.installedProbe?.scheme, 'viber');
    },
  );
}
