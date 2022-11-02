import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cube/flutter_cube.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:http/http.dart' as http;
import 'package:osjaddfnjosdfgn/filelist.dart';
import 'package:three_dart/three3d/math/math.dart';
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
      home: ThreeRender()
    );
  }
}

class ThreeRender extends StatefulWidget {
  const ThreeRender({Key? key}) : super(key: key);

  @override
  State<ThreeRender> createState() => _ThreeRender();
}

class _ThreeRender extends State<ThreeRender> {

  List<ArchiveFile> objectFiles = List<ArchiveFile>.empty(growable: true);

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

  late three.WebGLRenderTarget renderTarget;

  dynamic sourceTexture;

  final GlobalKey<three_jsm.DomLikeListenableState> _globalKey =
      GlobalKey<three_jsm.DomLikeListenableState>();

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
        title: Text("TEST WEBGL"),
      ),
      body: Builder(
        builder: (BuildContext context) {
          initSize(context);
          return SingleChildScrollView(child: _build(context));
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

    // 重要 更新纹理之前一定要调用 确保gl程序执行完毕
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
      var pars = three.WebGLRenderTargetOptions({
        "minFilter": three.LinearFilter,
        "magFilter": three.LinearFilter,
        "format": three.RGBAFormat
      });
      renderTarget = three.WebGLRenderTarget(
          (width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderTarget.samples = 4;
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
    }
  }

  initScene() {
    initRenderer();
    initPage();
  }

  formatValue(String input){
    return Math.round(double.parse(input) / 10) / 100;
  }

  initPage() async {
    scene = three.Scene();
    camera = three.PerspectiveCamera(40, width / height, 1, 100000);
    camera.position.set(0, 0, 1000);
    scene.add(camera);

    scene.background = three.Color(0x808080);

    var ambientLight = three.AmbientLight(0x404040);
    ambientLight.intensity = 3;
    scene.add(ambientLight);

    var directionalLight = three.DirectionalLight(0xffffff, 0.3);
    scene.add(directionalLight);

    controls = three_jsm.OrbitControls(camera, _globalKey);

    controls.minDistance = 10;
    controls.maxDistance = 30000;

    // var material = three.MeshBasicMaterial(three.Color{0x00ff00});
    var loader = three_jsm.OBJLoader(null);

    bool first = true;

    fetchFiles().then((archive) => {
      setState(() {
        var group = three.Group();
        var archiveFiles = 0;
        archive.files.forEach((file) {
          var decode = utf8.decode(file.content);
          List<String> split;
          List<String> formated = List.empty(growable: true);
          decode.split('\n').forEach((line) => {
            split = line.split(' '),
            if (split.isNotEmpty && split.elementAt(0) == 'v'){
              formated.add(line)
              //formated.add(List.from(['v', formatValue(split.elementAt(1)), formatValue(split.elementAt(2)), formatValue(split.elementAt(3))]).join(' '))
            }
            else if (split.isNotEmpty && split.elementAt(0) == 'f'){
              formated.add(List.from(['f', split.elementAt(1).replaceAll("/", "//"), split.elementAt(2).replaceAll("/", "//"), split.elementAt(3).replaceAll("/", "//")]).join(' ')),
            }
            else if (line.trim() == ""){

            }
            else{
              formated.add(line)
            }
          });


          (loader.parse(formated.join('\n')) as Future<dynamic>).then((model) => {
            group.add(model),
            if (++archiveFiles == archive.files.length){
              scene.add(group),
              setView(group),
              animate()
            }
          });

          // if (first){
          //   var formated = List.empty(growable: true);
          //   List<String> split;
          //   decode.split('\n').forEach((line) => {
          //     split = line.split(' '),
          //     if (split.isNotEmpty && split.elementAt(0) == 'v'){
          //       formated.add(line)
          //       //formated.add(List.from(['v', formatValue(split.elementAt(1)), formatValue(split.elementAt(2)), formatValue(split.elementAt(3))]).join(' '))
          //     }
          //     else if (split.isNotEmpty && split.elementAt(0) == 'f'){
          //       formated.add(List.from(['f', split.elementAt(1).replaceAll("/", "//"), split.elementAt(2).replaceAll("/", "//"), split.elementAt(3).replaceAll("/", "//")]).join(' ')),
          //     }
          //     else if (line.trim() == ""){
          //
          //     }
          //     else{
          //       formated.add(line)
          //     }
          //   });
          //
          //   (loader.parse(formated.join('\n')) as Future<dynamic>).then((model) => {
          //     scene.add(model),
          //     setView(model),
          //     animate()
          //   });
          //   first = false;
          // }




          //loader.load('assets/pipe.obj', (model) => {
          // loader.load('assets/pipe.obj', (model) => {
          //   scene.add(model),
          //   setView(model),
          //   animate()
          // });

          // rootBundle.loadString('assets/pipe.obj').then((text) => {
          //   setState(() => {
          //     loader.parse(text)
          //   })
          // });





          // (loader.parse(decode) as Future<dynamic>).then((model3d) => {
          //   print(model3d);
          //   setState((){
          //     print("loaded");
          //     var qwe = model3d;
          //     var qw1 = 0;
          //   })
          // });


          // var object = loader.parse(decode) as three.Object3D;
          // group.add(object);
        });
        // scene.add(group);
        // setView(group);
        // animate();
        // scene.add(group);
        // setView(group);
        //
        // animate();
      })
    });

    // objectFiles.forEach((element) {
    //   print(element);
    //   group.add(loader.parse(element));
    // });
    // group.add(object);

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

  setView(three.Object3D object) {
    var boundingBox = three.Box3().setFromObject(object);

    var center = three.Vector3();
    var size = three.Vector3();
    boundingBox.getCenter(center);
    boundingBox.getSize(size);

    var fitOffset = 1.2;
    var maxSize = Math.max(size.x, Math.max(size.y, size.z));
    var fitHeightDistance =
        maxSize / (2 * Math.atan(Math.PI * camera.fov / 360));
    var fitWidthDistance = fitHeightDistance / camera.aspect;
    var distance = fitOffset * Math.max(fitHeightDistance, fitWidthDistance);

    var direction = controls.target
        .clone()
        .sub(camera.position)
        .normalize()
        .multiplyScalar(distance);

    controls.maxDistance = distance * 10;
    controls.target.copy(center);

    camera.near = distance / 100;
    camera.far = distance * 100;
    camera.updateProjectionMatrix();

    camera.position.copy(controls.target).sub(direction);

    controls.update();
  }
}
