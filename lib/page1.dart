import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gl/flutter_gl.dart';

import 'package:three_dart/three_dart.dart' as three;
import 'package:three_dart_jsm/three_dart_jsm.dart' as three_jsm;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ThreeRender(),
    );
  }
}

class ThreeRender extends StatefulWidget {
  const ThreeRender({Key? key}) : super(key: key);

  @override
  State<ThreeRender> createState() => _ThreeRender();
}

class _ThreeRender extends State<ThreeRender> {
  late FlutterGlPlugin three3dRender;
  three.WebGLRenderer? renderer;

  int? fboId;
  late double width;
  late double height;

  Size? screenSize;

  late three.Scene scene;
  late three.Camera camera;
  late three.Mesh mesh;

  double dpr = 1.0;

  var amount = 4;

  bool verbose = true;
  bool disposed = false;

  late three.Object3D object;

  late three.WebGLRenderTarget renderTarget;

  dynamic sourceTexture;

  final GlobalKey<three_jsm.DomLikeListenableState> _globalKey = GlobalKey<three_jsm.DomLikeListenableState>();

  late three_jsm.OrbitControls controls;

  @override
  void initState() {
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = screenSize!.height - 60;

    three3dRender = FlutterGlPlugin();

    Map<String, dynamic> options = {
      "antialias": true,
      "alpha": false,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr
    };

    await three3dRender.initialize(options: options);

    setState(() {});

    Future.delayed(const Duration(milliseconds: 100), () async {
      await three3dRender.prepareContext();

      initScene();
    });
  }

  initSize(BuildContext context) {
    if (screenSize != null) {
      return;
    }

    final mqd = MediaQuery.of(context);

    screenSize = mqd.size;
    dpr = mqd.devicePixelRatio;

    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("render"),
      ),
      body: Builder(
        builder: (BuildContext context) {
          initSize(context);
          return Container(
            child: _build(context),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Text("render"),
        onPressed: () {
          render();
        },
      ),
    );
  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            three_jsm.DomLikeListenable(
                key: _globalKey,
                builder: (BuildContext context) {
                  return Container(
                      width: width,
                      height: height,
                      color: Colors.black,
                      child: Builder(builder: (BuildContext context) {
                        if (kIsWeb) {
                          return three3dRender.isInitialized
                              ? HtmlElementView(viewType: three3dRender.textureId!.toString())
                              : Container();
                        } else {
                          return three3dRender.isInitialized
                              ? Texture(textureId: three3dRender.textureId!)
                              : Container();
                        }
                      }));
                }),
          ],
        ),
      ],
    );
  }

  render() {
    int t = DateTime.now().millisecondsSinceEpoch;
    final gl = three3dRender.gl;

    renderer!.render(scene, camera);

    int t1 = DateTime.now().millisecondsSinceEpoch;

    if (verbose) {
      print("render cost: ${t1 - t} ");
      print(renderer!.info.memory);
      print(renderer!.info.render);
    }

    // ?????? ????????????????????????????????? ??????gl??????????????????
    gl.flush();

    // var pixels = _gl.readCurrentPixels(0, 0, 10, 10);
    // print(" --------------pixels............. ");
    // print(pixels);

    if (verbose) print(" render: sourceTexture: $sourceTexture ");

    if (!kIsWeb) {
      three3dRender.updateTexture(sourceTexture);
    }
  }

  initRenderer() {
    Map<String, dynamic> options = {
      "width": width,
      "height": height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element
    };
    renderer = three.WebGLRenderer(options);
    renderer!.setPixelRatio(dpr);
    renderer!.setSize(width, height, false);
    renderer!.shadowMap.enabled = false;

    if (!kIsWeb) {
      var pars = three.WebGLRenderTargetOptions(
          {"minFilter": three.LinearFilter, "magFilter": three.LinearFilter, "format": three.RGBAFormat});
      renderTarget = three.WebGLRenderTarget((width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderTarget.samples = 4;
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
    }
  }

  initScene() {
    initRenderer();
    initPage();
  }

  initPage() async {
    scene = three.Scene();
    scene.background = three.Color(0xcccccc);
    // scene.fog = three.FogExp2(0xcccccc, 0.002);


    camera = three.PerspectiveCamera(60, width / height, 1, 1000);
    camera.position.set(41843, 99, 9429);

    // controls
    var loader = three_jsm.OBJLoader(null);
    object = await loader.loadAsync('assets/male02.obj');
    object.position.set(0, 0, 0);
    scene.add(object);

    controls = three_jsm.OrbitControls(camera, _globalKey);
    // controls.listenToKeyEvents( window );

    //controls.addEventListener( 'change', render ); // call this only in static scenes (i.e., if there is no animation loop)


    // object.scale.set(0.5, 0.5, 0.5);

    controls.enableDamping = true; // an animation loop is required when either damping or auto-rotation are enabled
    controls.dampingFactor = 0.05;

    controls.screenSpacePanning = false;

    controls.minDistance = 1;
    controls.maxDistance = 1000;

    controls.maxPolarAngle = three.Math.PI;

    // world

    // var geometry = three.CylinderGeometry(0, 10, 30, 4, 1);
    // var material = three.MeshPhongMaterial({"color": 0xffffff, "flatShading": true});
    // var mesh = three.Mesh(geometry, material);
    // scene.add(mesh);



    // lights

    var dirLight1 = three.DirectionalLight(0xffffff);
    dirLight1.position.set(1, 1, 1);
    scene.add(dirLight1);

    var dirLight2 = three.DirectionalLight(0x002288);
    dirLight2.position.set(-1, -1, -1);
    scene.add(dirLight2);

    var ambientLight = three.AmbientLight(0x222222);
    scene.add(ambientLight);

    animate();
  }

  animate() {
    if (!mounted || disposed) {
      return;
    }

    render();

    Future.delayed(const Duration(milliseconds: 40), () {
      animate();
    });
  }

  @override
  void dispose() {
    print(" dispose ............. ");

    disposed = true;
    three3dRender.dispose();

    super.dispose();
  }
}
