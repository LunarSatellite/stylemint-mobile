import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// A capability nobody can reach is a capability that does not exist. The
/// `commerce-intelligence` route family had no Flutter reference at all
/// before this feature; these checks make sure it keeps one.
///
/// They read the files as text rather than building a GoRouter, matching the
/// existing reachability tests, because building one needs the whole auth
/// stack.
void main() {
  late final router = File('lib/routes/app_router.dart').readAsStringSync();
  late final assistantScreen = File(
    'lib/features/customer/assistant/presentation/screens/'
    'assistant_conversation_screen.dart',
  ).readAsStringSync();
  late final productDetail = File(
    'lib/features/customer/discovery/presentation/screens/'
    'product_detail_screen.dart',
  ).readAsStringSync();
  late final dataSource = File(
    'lib/features/customer/commerce_intelligence/data/datasources/'
    'commerce_intelligence_remote_datasource.dart',
  ).readAsStringSync();

  test('the screen has a path and it is registered', () {
    expect(RouteNames.evidenceAnswers, '/minty/evidence');
    expect(router.contains('path: RouteNames.evidenceAnswers'), isTrue);
    expect(router.contains('EvidenceAnswerScreen()'), isTrue);
  });

  test('"evidence" is matched before the :conversationId parameter', () {
    final evidenceIndex = router.indexOf('path: RouteNames.evidenceAnswers');
    final paramIndex = router.indexOf('path: RouteNames.assistantConversation');
    expect(evidenceIndex, greaterThan(-1));
    expect(paramIndex, greaterThan(-1));
    expect(
      evidenceIndex,
      lessThan(paramIndex),
      reason: '"evidence" must never be read as a conversation id',
    );
  });

  test('the assistant, where shoppers already ask, links to it', () {
    expect(assistantScreen.contains('RouteNames.evidenceAnswers'), isTrue);
    expect(
      assistantScreen.contains(
        'Ask a question and see the evidence behind the answer',
      ),
      isTrue,
    );
  });

  test('the product page embeds the panel seeded with the product', () {
    expect(productDetail.contains('EvidenceAnswerPanel('), isTrue);
    expect(productDetail.contains('seedQuery: product.name'), isTrue);
    expect(productDetail.contains('currentProductId: product.id'), isTrue);
  });

  test('the data source targets the real route family', () {
    expect(
      dataSource.contains("'/v1/customer/commerce-intelligence'"),
      isTrue,
    );
    expect(dataSource.contains(r"'$base/answer'"), isTrue);
  });

  test('the data source offers no write of any kind', () {
    // Comments are stripped first: the file *documents* that it cannot
    // reach a cart, and that sentence must not fail its own check.
    final code = const LineSplitter()
        .convert(dataSource)
        .where((line) => !line.trimLeft().startsWith('//'))
        .join(' ')
        .toLowerCase();
    for (final forbidden in const [
      'cart',
      'checkout',
      'reserve',
      'price',
      'payment',
      'delete',
      'put(',
      'patch(',
    ]) {
      expect(
        code.contains(forbidden),
        isFalse,
        reason: 'the read-only data source mentions "$forbidden"',
      );
    }
  });
}
