import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/geometry.dart';
import 'package:flame/sprite.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:hold_labs/game/game.dart';
import 'package:hold_labs/game/gun_pickup.dart';
import 'package:hold_labs/game/h_object.dart';
import 'package:hold_labs/game/platform.dart';

enum PlayerAnimation { idle, run, jump, hit }

enum GunType { hot, cold }

class Player extends PositionComponent
    with HasGameReference<HoldLabsGame>, CollisionCallbacks, KeyboardHandler {
  Player({super.position, super.priority}) : super(anchor: Anchor.center);

  late final SpriteAnimationGroupComponent<PlayerAnimation> _body;
  late final CircleHitbox _circleHitbox;

  bool jump = false;
  bool _isOnGround = false;
  bool _moveLock = false;
  set moveLock(bool value) {
    _moveLock = value;
    if (_moveLock) {
      hAxisValue = 0;
    }
  }

  final _gravity = 10 * 60.0;
  final _moveSpeed = 100.0;
  final _jumpSpeed = 200.0;

  final _velocity = Vector2.zero();
  final _upVector = Vector2(0, -1);

  double _timeElapsed = 0;
  static const timePerFrame = 1 / 60;

  double hAxisValue = 0;
  double vAxisValue = 0;

  final cameraTarget = PositionComponent();
  final _gunHolder = PositionComponent();
  late final SpriteGroupComponent<GunType> _gunComponent;

  bool hasGun = false;

  RaycastResult<ShapeHitbox>? results;
  GunType? get gunType => _gunComponent.current;
  Vector2 get gunPosition => _gunComponent.absolutePosition;

  @override
  Future<void> onLoad() async {
    final spriteSheet = SpriteSheet(
      image: game.images.fromCache('Player.png'),
      srcSize: Vector2.all(16),
    );

    final animations = <PlayerAnimation, SpriteAnimation>{
      PlayerAnimation.idle: spriteSheet.createAnimation(row: 0, stepTime: 0.1),
      PlayerAnimation.run: spriteSheet.createAnimation(row: 1, stepTime: 0.05),
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
      current: PlayerAnimation.jump,
      children: [
        OpacityEffect.fadeIn(
          LinearEffectController(1),
        ),
      ],
    );
    _body.opacity = 0;
    await add(_body);

    size.setFrom(_body.size);

    await add(
      _circleHitbox = CircleHitbox.relative(
        0.8,
        parentSize: size,
        position: Vector2(size.x * 0.55, size.y * 0.6),
        anchor: Anchor.center,
      ),
    );

    _gunHolder.position = size * 0.5;
    await add(_gunHolder);

    _gunComponent = SpriteGroupComponent<GunType>(
      current: GunType.hot,
      position: Vector2(8, 0),
      anchor: Anchor.center,
      sprites: {
        GunType.hot: Sprite(
          game.images.fromCache('Guns.png'),
          srcSize: Vector2.all(16),
        ),
        GunType.cold: Sprite(
          game.images.fromCache('Guns.png'),
          srcSize: Vector2.all(16),
          srcPosition: Vector2(16, 0),
        ),
      },
    );
  }

  @override
  void updateTree(double dt) {
    _timeElapsed += dt;

    if (_timeElapsed > timePerFrame) {
      _timeElapsed -= timePerFrame;
      super.updateTree(timePerFrame);
    }
  }

  @override
  void update(double dt) {
    _velocity.y += _gravity * dt;
    _velocity.x = hAxisValue * _moveSpeed;

    if (jump) {
      if (_isOnGround) {
        _velocity.y = -_jumpSpeed;
        _isOnGround = false;
        FlameAudio.play('Jump.mp3');
      }
      jump = false;
    }

    _velocity.y = _velocity.y.clamp(-_jumpSpeed, 200);
    position += _velocity * dt;

    if (_velocity.x != 0.0) {
      _body.current = PlayerAnimation.run;
      if (_velocity.x.sign != scale.x.sign) {
        flipHorizontallyAroundCenter();
      }

      if (!_isOnGround) {
        _body.current = PlayerAnimation.jump;
      }
    } else {
      if (_isOnGround) {
        _body.current = PlayerAnimation.idle;
      } else {
        _body.current = PlayerAnimation.jump;
      }
    }

    if ((cameraTarget.position - absoluteCenter).length2 > 0.5) {
      cameraTarget.position.setValues(x, y);
    }

    if (hasGun) {
      _updateGunPosition();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Platform || other is HObject) {
      if (intersectionPoints.length == 2) {
        final midPoint = (intersectionPoints.elementAt(0) +
                intersectionPoints.elementAt(1)) *
            0.5;

        final collisionNormal = _circleHitbox.absoluteCenter - midPoint;
        final intersectionDepth = collisionNormal.length;
        collisionNormal.normalize();

        final separationVector = collisionNormal.scaled(
          _circleHitbox.radius - intersectionDepth,
        );

        if (_upVector.dot(collisionNormal) > 0.9) {
          _isOnGround = true;
          _velocity.y = 0;
        } else if (Vector2(0, 1).dot(collisionNormal) > 0.9) {
          if (_velocity.y.isNegative) {
            _velocity.y = 0;
          }
        } else {
          _velocity.y -=
              collisionNormal.scaled(collisionNormal.dot(_velocity)).y;
        }

        position += separationVector;
      }
    } else if (other is GunPickup) {
      other.removeFromParent();
      hasGun = true;
      _addGuns();
    }
    super.onCollision(intersectionPoints, other);
  }

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    hAxisValue = 0;
    vAxisValue = 0;

    if (!_moveLock) {
      hAxisValue += keysPressed.contains(LogicalKeyboardKey.keyA) ? -1 : 0;
      hAxisValue += keysPressed.contains(LogicalKeyboardKey.keyD) ? 1 : 0;

      if (keysPressed.contains(LogicalKeyboardKey.space)) {
        if (_isOnGround) {
          jump = true;
        }
      }
    }
    return true;
  }

  void _addGuns() {
    _gunHolder.add(_gunComponent);
  }

  void _updateGunPosition() {
    if (_gunComponent.isMounted) {
      final dir = game.mousePosition - position;
      _gunHolder.angle =
          (-dir.angleToSigned(_upVector)) * scale.x.sign - (pi * 0.5);

      if (game.isFiring) {
        final maxDistance = dir.normalize();

        final ray = Ray2(
          origin: _gunComponent.absolutePosition,
          direction: dir,
        );

        results = game.collisionDetection
            .raycast(ray, maxDistance: maxDistance, out: results);
        if (results?.isActive ?? false) {
          final other = results!.hitbox?.parent;
          if (other is HObject) {
            switch (_gunComponent.current) {
              case GunType.hot:
                other.isCooling = false;
                other.isHeating = true;
                break;
              case GunType.cold:
                other.isCooling = true;
                other.isHeating = false;
                break;
              case null:
                break;
            }
          }
        }
      }
    }
  }

  void switchGun() {
    _gunComponent.current =
        _gunComponent.current == GunType.cold ? GunType.hot : GunType.cold;
  }
}
