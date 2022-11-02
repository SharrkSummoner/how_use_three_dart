import 'package:flutter/material.dart';
import 'package:flutter_3d_obj/flutter_3d_obj.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter 3D Demo',
      home:Scaffold(
        appBar: AppBar(
          title: const Text("Flutter 3D"),
        ),
        body: Center(
          child: Object3D(
            size: const Size(400.0, 400.0),
            path: "assets/pipe.obj",
            asset: true,
          ),
        ),
      ),
    );
  }
}