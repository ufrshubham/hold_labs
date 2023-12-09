import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/experimental.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:hold_labs/game/game.dart';
import 'package:hold_labs/game/platform.dart';
import 'package:hold_labs/game/player.dart';
import 'package:hold_labs/game/tiled_object_ext.dart';

class Level extends PositionComponent with HasGameReference<HoldLabsGame> {
  @override
  Future<void> onLoad() async {
    final map = await TiledComponent.load('Level1.tmx', Vector2.all(16));
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
            final tiles = game.images.fromCache('Tiles.png');
            final portal = SpriteComponent(
              position: object.position,
              anchor: Anchor.center,
              scale: Vector2.all(1.2),
              sprite: Sprite(
                tiles,
                srcSize: Vector2.all(16),
                srcPosition: Vector2(16 * 2, 0),
              ),
              children: [
                RotateEffect.by(
                  -2 * pi,
                  EffectController(infinite: true, duration: 0.1),
                ),
              ],
            );
            await add(portal);

            final player = Player(position: object.position);
            await add(player);
            game.camera.follow(player.cameraTarget);
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
}
