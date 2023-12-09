import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';

extension TiledObjectExt on TiledObject {
  Vector2 get position => Vector2(x, y);
  Vector2 get size => Vector2(width, height);
}
