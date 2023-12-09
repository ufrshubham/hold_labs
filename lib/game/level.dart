import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:hold_labs/game/game.dart';
import 'package:hold_labs/game/platform.dart';
import 'package:hold_labs/game/player.dart';
import 'package:hold_labs/game/tiled_object_ext.dart';

class Level extends PositionComponent with HasGameReference<HoldLabsGame> {
  Level(this.levelId);

  final int levelId;
  late final Player _player;
  final _loadedAudio = <String>[];

  @override
  Future<void> onLoad() async {
    final map = await TiledComponent.load(
      'Level$levelId.tmx',
      Vector2.all(16),
    );
    await add(map);

    await _handleSpawnPoints(map);
    await _handleColliders(map);
    await _handleAudio(map);

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
              _player = Player(position: object.position, priority: 1);
              await add(_player);
              game.camera.follow(_player.cameraTarget);
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
    final collidersLayer = map.tileMap.getLayer<ObjectGroup>('Colliders');
    final objects = collidersLayer?.objects;

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

  Future<void> _handleAudio(TiledComponent map) async {
    final audioLayer = map.tileMap.getLayer<ObjectGroup>('AudioTriggers');
    final objects = audioLayer?.objects;

    if (objects != null) {
      for (final object in objects) {
        switch (object.class_) {
          case 'AutoStart':
            final audioPath = object.properties
                .getValue<String>('Audio')
                ?.split('audio/')
                .last;
            if (audioPath != null) {
              _player.moveLock = true;

              await FlameAudio.audioCache.load(audioPath);
              _loadedAudio.add(audioPath);

              final audioplayer = await FlameAudio.playLongAudio(audioPath);
              audioplayer.onPlayerComplete.listen(
                (event) {
                  _player.moveLock = false;
                },
              );
            }
            break;
          case 'Trigger':
            final audioPath = object.properties
                .getValue<String>('Audio')
                ?.split('audio/')
                .last;

            if (audioPath != null) {
              await FlameAudio.audioCache.load(audioPath);
              _loadedAudio.add(audioPath);
              final audioHitbox = RectangleHitbox(
                collisionType: CollisionType.passive,
              );

              final audioTrigger = PositionComponent(
                position: object.position,
                size: object.size,
                children: [audioHitbox],
              );

              audioHitbox.onCollisionStartCallback =
                  (intersectionPoints, other) => _onAudioTriggerEnter(
                        audioTrigger,
                        other,
                        audioPath,
                      );

              await add(audioTrigger);
            }

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

  void _onAudioTriggerEnter(
    PositionComponent audioTrigger,
    PositionComponent other,
    String filename,
  ) {
    if (other.parent is Player) {
      audioTrigger.removeFromParent();
      FlameAudio.playLongAudio(filename);
    }
  }

  @override
  void onRemove() {
    // for (final audio in _loadedAudio) {
    //   FlameAudio.audioCache.clear(audio);
    // }
  }
}
