import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// A guard, not a widget test.
//
// The cancelled-order history used to invent its own narration, including
// sentences that correspond to no record anywhere in the system — nothing in
// Orders, Delivery or the custody chain ever produces them, so no backend
// change could ever make them true. They were deleted; this asserts they
// cannot creep back in as a fallback, a placeholder or a greyed-out step.
//
// It scans the source rather than a rendered tree deliberately: a widget test
// only proves the string is not on one screen under one set of inputs.

/// Sentences with no source behind them, at all.
const _unsourced = [
  'The package is being checked in the transit',
  'The package is in the shipping lane',
  'The package is being tagged with the shipping address details',
];

/// Real only when the vendor used the seller steps, in which case the backend
/// sends `packed` with its own sentence. Hard-coded client-side it is a guess.
const _onlyEverTheBackends = [
  'Order items are being gathered & packaged for shipping',
];

void main() {
  test('no invented order-event narration survives anywhere in lib/', () {
    final lib = Directory('lib');
    expect(
      lib.existsSync(),
      isTrue,
      reason: 'run from the package root so lib/ is scannable',
    );

    final offenders = <String>[];
    for (final entity in lib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final phrase in [..._unsourced, ..._onlyEverTheBackends]) {
        if (source.contains(phrase)) {
          offenders.add('${entity.path}: "$phrase"');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These sentences describe events no system of record produces. '
          "The order history renders the endpoint's own `statement` text; "
          'it does not narrate.\n${offenders.join('\n')}',
    );
  });
}
