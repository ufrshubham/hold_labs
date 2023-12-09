import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/palette.dart';

class HObject extends PositionComponent with HasPaint, Snapshot {
  HObject({
    super.position,
    super.size,
    this.temperatureFactor = 0.0,
    this.temperatureChangeRate = 1.0,
  });

  static const _atomicSize = 10.0;
  static const _atomicRadius = _atomicSize * 0.6;
  static final _random = Random();

  double temperatureFactor;
  double temperatureChangeRate;
  bool isHeating = false;
  bool isCooling = false;

  late final _paint = Paint()..color = _tempColor;
  final _internalObject = _HObjectInternal();

  Color get _tempColor => Color.lerp(
        BasicPalette.blue.color,
        BasicPalette.red.color,
        temperatureFactor,
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
    final nRow = size.y / _atomicSize;
    final nCol = size.x / _atomicSize;

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
    _updateTemperature();
  }

  @override
  void update(double dt) {
    if (isCooling) {
      temperatureFactor -= temperatureChangeRate * dt;
      _updateTemperature();
    }

    if (isHeating) {
      temperatureFactor += temperatureChangeRate * dt;
      _updateTemperature();
    }
  }

  void _updateTemperature() {
    temperatureFactor = temperatureFactor.clamp(0, 1);
    _paint.color = _tempColor;

    _internalObject.timeScale = temperatureFactor;
    renderSnapshot = _timer.timer.finished && temperatureFactor == 0.0;
  }
}

class _HObjectInternal extends PositionComponent with HasTimeScale {}

class _HAtom extends CircleComponent {
  _HAtom({super.position, super.radius, super.paint, super.children});
}
