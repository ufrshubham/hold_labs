import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hold_labs/game/level.dart';

class HoldLabsGame extends FlameGame with HasCollisionDetection {
  HoldLabsGame()
      : super(
          camera: CameraComponent.withFixedResolution(width: 320, height: 180),
        );

  @override
  Color backgroundColor() {
    return const Color.fromARGB(255, 109, 100, 100);
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
      ],
    );
    await world.add(Level());
  }
}
