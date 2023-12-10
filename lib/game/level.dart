import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:hold_labs/game/button.dart';
import 'package:hold_labs/game/door.dart';
import 'package:hold_labs/game/game.dart';
import 'package:hold_labs/game/gun_pickup.dart';
import 'package:hold_labs/game/h_object.dart';
import 'package:hold_labs/game/platform.dart';
import 'package:hold_labs/game/player.dart';
import 'package:hold_labs/game/tiled_object_ext.dart';

class Level extends PositionComponent with HasGameReference<HoldLabsGame> {
  Level(this.levelId);

  final int levelId;
  late final Player player;
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
              player = Player(
                position: object.position,
                priority: 1,
                hasGun: levelId > 4,
              );
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
          case 'HotButton':
            final blasterId = object.properties.getValue<int>('Blaster');

            if (blasterId != null) {
              final blasterObject = map.tileMap.map.objectById(blasterId);
              final targetId =
                  blasterObject?.properties.getValue<int>('Target');

              if (targetId != null) {
                final targetObject = map.tileMap.map.objectById(targetId);

                if (targetObject != null) {
                  final hotButton = HotButton(
                    blasterStart: blasterObject!.position,
                    blasterEnd: targetObject.position,
                    position: object.position,
                  );
                  await add(hotButton);
                }
              }
            }

            break;
          case 'ColdButton':
            final blasterId = object.properties.getValue<int>('Blaster');

            if (blasterId != null) {
              final blasterObject = map.tileMap.map.objectById(blasterId);
              final targetId =
                  blasterObject?.properties.getValue<int>('Target');

              if (targetId != null) {
                final targetObject = map.tileMap.map.objectById(targetId);

                if (targetObject != null) {
                  final hotButton = ColdButton(
                    blasterStart: blasterObject!.position,
                    blasterEnd: targetObject.position,
                    position: object.position,
                  );
                  await add(hotButton);
                }
              }
            }
            break;
          case 'Guns':
            final gunsPickup = GunPickup(position: object.position);
            await add(gunsPickup);
            break;
          case 'Door':
            final door = Door(position: object.position);
            await add(door);
            break;
          case 'Hostage':
            final hostage = SpriteAnimationComponent.fromFrameData(
              position: object.position,
              game.images.fromCache('Player.png'),
              SpriteAnimationData.sequenced(
                amount: 4,
                stepTime: 0.1,
                textureSize: Vector2.all(16),
              ),
            );
            await add(hostage);
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
          case 'HObject':
            final hotHeightId = object.properties.getValue<int>('HotHeight');
            final coldHeightId = object.properties.getValue<int>('ColdHeight');

            Vector2? hotHeight;
            Vector2? coldHeight;

            if (hotHeightId != null) {
              hotHeight = map.tileMap.map.objectById(hotHeightId)?.position;
            }
            if (coldHeightId != null) {
              coldHeight = map.tileMap.map.objectById(coldHeightId)?.position;
            }

            final hObject = HObject(
              position: object.position,
              size: object.size,
              temperatureFactor: object.properties.getValue<double>(
                'TemperatureFactor',
              ),
              temperatureChangeRate: object.properties.getValue<double>(
                'TemperatureChangeRate',
              ),
              atomicSize: object.properties.getValue<double>('AtomicSize'),
              hotHeight: hotHeight,
              coldHeight: coldHeight,
            );
            await add(hObject);
            break;
        }
      }
    }
  }

  Future<void> _handleAudio(TiledComponent map) async {
    final audioLayer = map.tileMap.getLayer<ObjectGroup>('AudioTriggers');
    final objects = audioLayer?.objects;
    final visible = audioLayer?.visible ?? false;

    if (visible && objects != null) {
      for (final object in objects) {
        switch (object.class_) {
          case 'AutoStart':
            final audioPath = object.properties
                .getValue<String>('Audio')
                ?.split('audio/')
                .last;
            if (audioPath != null) {
              FlameAudio.bgm.pause();
              player.moveLock = true;

              await FlameAudio.audioCache.load(audioPath);
              _loadedAudio.add(audioPath);

              final audioplayer = await FlameAudio.playLongAudio(audioPath);
              audioplayer.onPlayerComplete.listen(
                (event) {
                  player.moveLock = false;
                  FlameAudio.bgm.resume();
                },
              );
            }
            break;
          case 'Trigger':
            final audioPath = object.properties
                .getValue<String>('Audio')
                ?.split('audio/')
                .last;

            final holdInput = object.properties.getValue<bool>('HoldInput');

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
                        holdInput ?? false,
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
      game.changeLevel(levelId + 1);
    }
  }

  Future<void> _onAudioTriggerEnter(
    PositionComponent audioTrigger,
    PositionComponent other,
    String filename,
    bool holdInput,
  ) async {
    if (other.parent is Player) {
      audioTrigger.removeFromParent();

      if (holdInput) {
        FlameAudio.bgm.pause();
        player.moveLock = true;
      }

      final audioplayer = await FlameAudio.playLongAudio(filename);
      audioplayer.onPlayerComplete.listen((event) {
        player.moveLock = false;
        FlameAudio.bgm.resume();
      });
    }
  }

  @override
  void onRemove() {
    // for (final audio in _loadedAudio) {
    //   FlameAudio.audioCache.clear(audio);
    // }
  }
}
