import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hold_labs/game/player.dart';

class HoldLabsGame extends FlameGame {
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

    await images.loadAll(['Player.png']);
    await world.add(Player());
  }
}
