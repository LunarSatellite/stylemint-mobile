import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/vcard.dart';

const _url = 'https://stylemint.voyageritnepal.com/c/7K9M2PQR';

void main() {
  test('carries the name, profile link and StyleMint note', () {
    final card = buildProfileVCard(displayName: 'Asha Rai', profileUrl: _url);

    expect(card, startsWith('BEGIN:VCARD\r\nVERSION:3.0\r\n'));
    expect(card, contains('N:;Asha Rai;;;\r\n'));
    expect(card, contains('FN:Asha Rai\r\n'));
    expect(card, contains('URL:$_url\r\n'));
    expect(card, contains('NOTE:StyleMint\r\n'));
    expect(card, endsWith('END:VCARD\r\n'));
  });

  test('leaves the phone number out by default', () {
    final card = buildProfileVCard(displayName: 'Asha Rai', profileUrl: _url);

    expect(card, isNot(contains('TEL')));
  });

  test('adds the phone number only when one is passed', () {
    final withPhone = buildProfileVCard(
      displayName: 'Asha Rai',
      profileUrl: _url,
      phone: '+977 981-234 5678',
    );
    final blank = buildProfileVCard(
      displayName: 'Asha Rai',
      profileUrl: _url,
      phone: '   ',
    );

    expect(withPhone, contains('TEL;TYPE=CELL:+9779812345678\r\n'));
    expect(blank, isNot(contains('TEL')));
  });

  test('escapes commas, semicolons, backslashes and line breaks', () {
    final card = buildProfileVCard(
      displayName: 'Rai, Asha; Mint\\Shop\nKTM',
      profileUrl: _url,
    );

    expect(
      card,
      contains(
        r'FN:Rai\, Asha\; Mint\\Shop\nKTM'
        '\r\n',
      ),
    );
    expect(escapeVCardText('a\r\nb'), r'a\nb');
  });

  test('a link with line breaks cannot add properties', () {
    final card = buildProfileVCard(
      displayName: 'Asha',
      profileUrl: '$_url\r\nTEL:123',
    );

    expect(card, isNot(contains('\r\nTEL')));
  });

  test('an empty name still makes a valid card and file name', () {
    final card = buildProfileVCard(displayName: '  ', profileUrl: _url);

    expect(card, contains('FN:StyleMint member\r\n'));
    expect(profileVCardFileName('Asha Rai!'), 'asha-rai.vcf');
    expect(profileVCardFileName(''), 'stylemint-contact.vcf');
  });
}
