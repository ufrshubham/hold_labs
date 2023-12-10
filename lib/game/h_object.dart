import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/palette.dart';

class HObject extends PositionComponent with HasPaint, Snapshot {
  HObject({
    super.position,
    super.size,
    double? temperatureFactor,
    double? temperatureChangeRate,
    double? atomicSize,
    Vector2? hotHeight,
    Vector2? coldHeight,
  })  : _temperatureFactor = temperatureFactor ?? 0.0,
        _temperatureChangeRate = temperatureChangeRate ?? 1.0,
        _atomicSize = atomicSize ?? 5.0,
        _hotHeight = hotHeight?.clone() ?? position?.clone() ?? Vector2.zero(),
        _coldHeight =
            coldHeight?.clone() ?? position?.clone() ?? Vector2.zero();

  late final _atomicRadius = _atomicSize * 0.6;
  static final _random = Random();

  double _temperatureFactor;
  final double _temperatureChangeRate;
  final double _atomicSize;
  bool isHeating = false;
  bool isCooling = false;

  late final _paint = Paint()..color = _tempColor;
  final _internalObject = _HObjectInternal();

  final Vector2 _hotHeight;
  final Vector2 _coldHeight;

  Color get _tempColor => Color.lerp(
        BasicPalette.blue.color,
        BasicPalette.red.color,
        _temperatureFactor,
      )!;

  late final _timer = TimerComponent(
    period: 1,
    onTick: _updateTemperature,
    removeOnFinish: true,
  );

  @override
  Paint get paint => _paint;

  @override
  Future<void> onLoad() async {
    final nRow = (size.y / _atomicSize).floor();
    final nCol = (size.x / _atomicSize).floor();

    for (var i = 0; i < nRow; ++i) {
      for (var j = 0; j < nCol; ++j) {
        final rV =
            Vector2(2 * _random.nextDouble() - 1, 2 * _random.nextDouble() - 1);

        await _internalObject.add(
          _HAtom(
            position: Vector2(j * _atomicSize, i * _atomicSize),
            radius: _atomicRadius,
            paint: _paint,
            children: [
              MoveEffect.by(
                rV * 5,
                EffectController(
                  alternate: true,
                  duration: 0.1 + _random.nextDouble() * 0.1,
                  infinite: true,
                ),
              ),
            ],
          ),
        );
      }
    }

    await add(_internalObject);
    await add(_timer);
    await add(RectangleHitbox(collisionType: CollisionType.passive));
    _updateTemperature();
  }

  @override
  void update(double dt) {
    if (isCooling) {
      _temperatureFactor -= _temperatureChangeRate * dt;
      _updateTemperature();
    }

    if (isHeating) {
      _temperatureFactor += _temperatureChangeRate * dt;
      _updateTemperature();

      position.y = lerpDouble(_coldHeight.y, _hotHeight.y, _temperatureFactor)!;
    }
  }

  void _updateTemperature() {
    _temperatureFactor = _temperatureFactor.clamp(0, 1);
    _paint.color = _tempColor;

    _internalObject.timeScale = _temperatureFactor;
    renderSnapshot = _timer.timer.finished && _temperatureFactor == 0.0;
  }
}

class _HObjectInternal extends PositionComponent with HasTimeScale {}

class _HAtom extends CircleComponent {
  _HAtom({super.position, super.radius, super.paint, super.children});
}
