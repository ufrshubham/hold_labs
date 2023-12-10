import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
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
    changeLevel(2);
  }

  void changeLevel(int levelId) {
    currentLevel?.removeFromParent();
    currentLevel = Level(levelId);
    world.add(currentLevel!);
  }
}
