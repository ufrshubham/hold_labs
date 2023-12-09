import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:hold_labs/game/game.dart';

void main() {
  runApp(const HoldLabsApp());
}

class HoldLabsApp extends StatelessWidget {
  const HoldLabsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: GameWidget.controlled(
          gameFactory: HoldLabsGame.new,
        ),
      ),
    );
  }
}
