import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/mascot/data/buddy_api.dart';
import 'package:riksa_app/features/mascot/domain/mascot.dart';
import 'package:riksa_app/features/mascot/presentation/widgets/buddy_anchors.dart';

void main() {
  test('a frame anchor partially overrides its slot default', () {
    final anchors = BuddyAnchorSet.fromJson({
      'version': 1,
      'face': {
        'default': {
          'HAT': {'x': .5, 'y': .1, 'w': .6, 'rot': 5},
          'EYEWEAR': {'x': .55, 'y': .45, 'w': .5, 'rot': 0},
        },
        'frames': {
          'happy_2': {
            'HAT': {'y': .04},
          },
        },
      },
    }, species: MascotSpecies.crocodile);

    final hat = anchors.forFrame(BuddyItemSlot.hat, 'happy_2');
    expect(hat.x, .5);
    expect(hat.y, .04);
    expect(hat.width, .6);
    expect(hat.rotation, 5);

    final glasses = anchors.forFrame(BuddyItemSlot.eyewear, 'happy_2');
    expect(glasses.y, .45);
  });
}
