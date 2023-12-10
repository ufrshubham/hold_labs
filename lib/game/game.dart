import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hold_labs/game/level.dart';
import 'package:hold_labs/game/player.dart';

class HoldLabsGame extends FlameGame
    with
        HasCollisionDetection,
        HasKeyboardHandlerComponents,
        MouseMovementDetector,
        TapCallbacks,
        SecondaryTapDetector,
        ScrollDetector,
        PanDetector {
  HoldLabsGame()
      : super(
          camera: CameraComponent.withFixedResolution(width: 320, height: 180),
        );

  Level? currentLevel;
  final Vector2 mousePosition = Vector2.zero();

  final _redGunPaint = BasicPalette.red.paint()..strokeWidth = 4;
  final _blueGunPaint = BasicPalette.blue.paint()..strokeWidth = 4;

  bool isFiring = false;

  @override
  Color backgroundColor() {
    return const Color.fromARGB(255, 184, 187, 202);
  }

  @override
  Future<void> onLoad() async {
    if (kDebugMode) {
      await add(FpsTextComponent());
    }

    await images.loadAll(
      [
        'Player.png',
        'Tiles.png',
        'PortalPad.png',
        'Buttons.png',
        'Guns.png',
      ],
    );

    FlameAudio.bgm.initialize();
    await FlameAudio.audioCache.loadAll(
      [
        'Laser.mp3',
        'Jump.mp3',
        'Button.mp3',
      ],
    );
    await FlameAudio.bgm.play('HoldLabs-Music.mp3', volume: 0.8);
    changeLevel(4);
  }

  void changeLevel(int levelId) {
    currentLevel?.removeFromParent();
    currentLevel = Level(min(levelId, 4));
    world.add(currentLevel!);
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    mousePosition.setFrom(camera.globalToLocal(info.eventPosition.global));
  }

  @override
  void onPanDown(DragDownInfo info) {
    isFiring = true;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    isFiring = true;
    mousePosition.setFrom(camera.globalToLocal(info.eventPosition.global));
  }

  @override
  void onPanStart(DragStartInfo info) {
    isFiring = true;
  }

  @override
  void onPanEnd(DragEndInfo info) {
    isFiring = false;
  }

  @override
  void onPanCancel() {
    isFiring = false;
  }

  @override
  void onSecondaryTapDown(TapDownInfo info) {
    if (currentLevel?.isMounted ?? false) {
      if (currentLevel!.player.hasGun) {
        currentLevel?.player.switchGun();
      }
    }
  }

  @override
  void onScroll(PointerScrollInfo info) {
    if (currentLevel?.isMounted ?? false) {
      if (currentLevel!.player.hasGun) {
        currentLevel?.player.switchGun();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (currentLevel?.isMounted ?? false) {
      final player = currentLevel!.player;

      if (player.hasGun && isFiring) {
        if ((currentLevel!.player.results?.isActive ?? false) &&
            currentLevel!.player.results!.intersectionPoint != null) {
          canvas.drawLine(
            camera.localToGlobal(currentLevel!.player.gunPosition).toOffset(),
            camera
                .localToGlobal(currentLevel!.player.results!.intersectionPoint!)
                .toOffset(),
            player.gunType == GunType.hot ? _redGunPaint : _blueGunPaint,
          );
        }
      }
    }
  }
}
