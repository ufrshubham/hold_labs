import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:hold_labs/game/game.dart';

enum PlayerAnimation { idle, run, jump, hit }

class Player extends PositionComponent with HasGameReference<HoldLabsGame> {
  Player({super.position});

  late final SpriteAnimationGroupComponent<PlayerAnimation> _body;

  @override
  Future<void> onLoad() async {
    final spriteSheet = SpriteSheet(
      image: game.images.fromCache('Player.png'),
      srcSize: Vector2.all(16),
    );

    final animations = <PlayerAnimation, SpriteAnimation>{
      PlayerAnimation.idle: spriteSheet.createAnimation(row: 0, stepTime: 0.1),
      PlayerAnimation.run: spriteSheet.createAnimation(row: 1, stepTime: 0.1),
      PlayerAnimation.jump: spriteSheet.createAnimation(
        row: 2,
        stepTime: 0.1,
        loop: false,
      ),
      PlayerAnimation.hit: spriteSheet.createAnimation(
        row: 3,
        stepTime: 0.1,
        loop: false,
      ),
    };

    _body = SpriteAnimationGroupComponent<PlayerAnimation>(
      animations: animations,
      current: PlayerAnimation.hit,
    );
    await add(_body);

    size.setFrom(_body.size);
  }
}
