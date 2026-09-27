import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Khmer ARB contains no TODO placeholders', () {
    final arb =
        jsonDecode(File('lib/l10n/app_km.arb').readAsStringSync())
            as Map<String, dynamic>;
    final unresolvedKeys = arb.entries
        .where(
          (entry) =>
              entry.value is String &&
              (entry.value as String).startsWith('TODO'),
        )
        .map((entry) => entry.key)
        .toList();

    expect(
      unresolvedKeys,
      isEmpty,
      reason: 'Untranslated Khmer values: ${unresolvedKeys.join(', ')}',
    );
  });
}
