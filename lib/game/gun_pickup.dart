import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:hold_labs/game/game.dart';

class GunPickup extends PositionComponent with HasGameReference<HoldLabsGame> {
  GunPickup({super.position});

  late final SpriteAnimationComponent _guns;

  @override
  Future<void> onLoad() async {
    _guns = SpriteAnimationComponent.fromFrameData(
      game.images.fromCache('Guns.png'),
      SpriteAnimationData.sequenced(
        amount: 2,
        stepTime: 0.3,
        textureSize: Vector2.all(16),
      ),
    );

    size = _guns.size;

    await add(_guns);
    await add(
      RectangleHitbox.relative(
        Vector2(0.5, 0.5),
        parentSize: size,
        collisionType: CollisionType.passive,
      ),
    );
  }
}
