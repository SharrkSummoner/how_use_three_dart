import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planet',
      theme: ThemeData.dark(),
      home: MyHomePage(title: 'Planet'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late Scene _scene;
  Object? _earth;
  late Object _stars;
  late AnimationController _controller;


  void _onSceneCreated(Scene scene) {
    _scene = scene;
    _scene.camera.position.z = 16;

    // model from https://free3d.com/3d-model/planet-earth-99065.html
    _earth = Object(name: 'earth', scale: Vector3(0.0, 0.0, 0.0),
        backfaceCulling: true, fileName: 'earth/pipe.obj');


    _scene.world.add(_earth!);

  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: Duration(milliseconds: 30000), vsync: this)
      ..addListener(() {
        if (_earth != null) {
          _earth!.rotation.y = _controller.value * 360;
          _earth!.updateTransform();
          _scene.update();
        }
      })
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Cube(onSceneCreated: _onSceneCreated),
    );
  }
}