import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:hold_labs/game/game.dart';
import 'package:hold_labs/game/platform.dart';
import 'package:hold_labs/game/player.dart';
import 'package:hold_labs/game/tiled_object_ext.dart';

class Level extends PositionComponent with HasGameReference<HoldLabsGame> {
  Level(this.levelId);

  final int levelId;

  @override
  Future<void> onLoad() async {
    final map = await TiledComponent.load(
      'Level$levelId.tmx',
      Vector2.all(16),
    );
    await add(map);

    await _handleSpawnPoints(map);
    await _handleColliders(map);

    final halfResolution = game.camera.viewport.virtualSize * 0.5;
    game.camera.setBounds(
      Rectangle.fromLTRB(
        halfResolution.x,
        halfResolution.y,
        map.width - halfResolution.x,
        map.height - halfResolution.y,
      ),
    );
  }

  Future<void> _handleSpawnPoints(TiledComponent map) async {
    final spawnPointsLayer = map.tileMap.getLayer<ObjectGroup>('SpawnPoints');
    final objects = spawnPointsLayer?.objects;

    if (objects != null) {
      for (final object in objects) {
        switch (object.class_) {
          case 'Start':
          case 'End':
            final portal = SpriteAnimationComponent.fromFrameData(
              position: object.position - Vector2(0, 3),
              anchor: Anchor.topCenter,
              scale: Vector2.all(1.2),
              priority: 2,
              game.images.fromCache('PortalPad.png'),
              SpriteAnimationData.sequenced(
                amount: 3,
                stepTime: 0.2,
                textureSize: Vector2.all(16),
              ),
            );
            await add(portal);

            if (object.class_ == 'Start') {
              final player = Player(position: object.position, priority: 1);
              await add(player);
              game.camera.follow(player.cameraTarget);
            } else {
              final portalHitbox = RectangleHitbox(
                collisionType: CollisionType.passive,
              );
              portalHitbox.onCollisionStartCallback =
                  (_, other) => _onPortalEnter(other);
              await portal.add(portalHitbox);
            }
            break;
        }
      }
    }
  }

  Future<void> _handleColliders(TiledComponent map) async {
    final spawnPointsLayer = map.tileMap.getLayer<ObjectGroup>('Colliders');
    final objects = spawnPointsLayer?.objects;

    if (objects != null) {
      for (final object in objects) {
        switch (object.class_) {
          case 'Platform':
            final portal = Platform(
              position: object.position,
              size: object.size,
            );
            await add(portal);
            break;
        }
      }
    }
  }

  void _onPortalEnter(PositionComponent other) {
    if (other.parent is Player) {
      game.changeLevel(levelId);
    }
  }
}
