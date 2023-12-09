import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Platform extends PositionComponent {
  Platform({super.position, super.size});

  @override
  Future<void> onLoad() async {
    await add(RectangleHitbox(collisionType: CollisionType.passive));
  }
}
