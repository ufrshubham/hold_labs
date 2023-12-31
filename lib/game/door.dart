import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:hold_labs/game/game.dart';
import 'package:hold_labs/game/player.dart';

class Door extends PositionComponent
    with HasGameReference<HoldLabsGame>, CollisionCallbacks {
  Door({super.position, this.exitDoor = false});

  late final SpriteComponent _internalDoor;
  final bool exitDoor;

  @override
  Future<void> onLoad() async {
    _internalDoor = SpriteComponent.fromImage(
      game.images.fromCache('Tiles.png'),
      srcSize: Vector2.all(16),
      srcPosition: Vector2(0, 32),
    );

    size = _internalDoor.size;
    await add(_internalDoor);
    await add(
      RectangleHitbox(collisionType: CollisionType.passive),
    );
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is Player) {
      other.moveLock = true;
      if (!exitDoor) {
        game.changeLevel(7);
      } else {
        game.exit();
      }
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}
