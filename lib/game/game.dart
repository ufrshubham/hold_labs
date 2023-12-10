import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hold_labs/game/level.dart';

class HoldLabsGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents {
  HoldLabsGame()
      : super(
          camera: CameraComponent.withFixedResolution(width: 320, height: 180),
        );

  Level? currentLevel;

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
    changeLevel(1);
  }

  void changeLevel(int levelId) {
    currentLevel?.removeFromParent();
    currentLevel = Level(min(levelId, 3));
    world.add(currentLevel!);
  }
}
