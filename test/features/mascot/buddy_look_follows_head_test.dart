import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/mascot/data/buddy_api.dart';
import 'package:riksa_app/features/mascot/domain/mascot.dart';
import 'package:riksa_app/features/mascot/presentation/widgets/buddy_look.dart';
import 'package:riksa_app/features/mascot/presentation/widgets/sprite_frames.dart';

void main() {
  // The head pops, wobbles and bobs. A hat drawn outside those transforms
  // stays put while the head moves, so it looks too small and off to one side.
  testWidgets('equipped items move inside the head animation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: BuddyLook(
            species: MascotSpecies.capybara,
            face: MascotFace.love,
            equipped: {
              BuddyItemSlot.hat: 'hat_straw',
              BuddyItemSlot.eyewear: 'eye_round',
            },
            size: 76,
            loops: 1,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    final head = find.byType(SpriteFrames);
    expect(head, findsOneWidget);
    final headTransforms = find
        .ancestor(of: head, matching: find.byType(Transform))
        .evaluate()
        .toSet();
    expect(headTransforms, isNotEmpty);

    final items = find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter is BuddyItemPlaceholderPainter,
    );
    expect(items, findsNWidgets(2));
    for (final item in items.evaluate()) {
      final itemTransforms = find
          .ancestor(
            of: find.byWidget(item.widget),
            matching: find.byType(Transform),
          )
          .evaluate()
          .toSet();
      expect(
        itemTransforms.containsAll(headTransforms),
        isTrue,
        reason: 'every transform that moves the head must move the item too',
      );
    }

    await tester.pumpAndSettle();
  });
}
