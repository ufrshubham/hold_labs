import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:flame/palette.dart';
import 'package:hold_labs/game/game.dart';
import 'package:hold_labs/game/h_object.dart';
import 'package:hold_labs/game/player.dart';

class HotButton extends PositionComponent
    with HasGameReference<HoldLabsGame>, CollisionCallbacks {
  HotButton({
    required this.blasterStart,
    required this.blasterEnd,
    super.position,
  });

  final Vector2 blasterStart;
  final Vector2 blasterEnd;

  late final SpriteAnimationComponent _internalButton;
  late final _ray = Ray2(
    origin: blasterStart,
    direction: (blasterEnd - blasterStart).normalized(),
  );
  static final _blasterPaint = BasicPalette.red.paint();
  bool _isActive = false;

  late final _maxDistance = (blasterStart - blasterEnd).length;
  RaycastResult<ShapeHitbox>? _results;

  @override
  Future<void> onLoad() async {
    _internalButton = SpriteAnimationComponent.fromFrameData(
      game.images.fromCache('Buttons.png'),
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.1,
        textureSize: Vector2.all(16),
        loop: false,
      ),
    );

    _internalButton.playing = false;
    size = _internalButton.size;

    await add(_internalButton);
    await add(
      RectangleHitbox.relative(
        Vector2(1, 0.5),
        position: Vector2(0, size.y * 0.5),
        parentSize: size,
        collisionType: CollisionType.passive,
      ),
    );
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Player) {
      _isActive = true;
      _internalButton.playing = true;
      parent?.add(
        RectangleComponent.fromRect(
          Rect.fromLTRB(
            blasterStart.x,
            blasterStart.y,
            blasterEnd.x,
            blasterEnd.y,
          ),
          paint: _blasterPaint,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    if (_isActive) {
      _results = game.collisionDetection.raycast(
        _ray,
        maxDistance: _maxDistance,
        out: _results,
      );

      if (_results != null && _results!.isActive) {
        final other = _results!.hitbox?.parent;
        if (other is HObject) {
          other.isHeating = true;
        }
      }
    }
  }
}
