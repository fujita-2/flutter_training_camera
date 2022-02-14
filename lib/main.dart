import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() async {
  // runAppが実行される前に、cameraプラグインを初期化
  WidgetsFlutterBinding.ensureInitialized();

  // デバイスで使用可能なカメラの一覧を取得する
  final cameras = await availableCameras();

  // 利用可能なカメラの一覧から、指定のカメラを取得する
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  const MyApp({Key? key, required this.camera}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CameraHome(camera: camera),
    );
  }
}

// ①
class CameraHome extends StatefulWidget {
  final CameraDescription camera;

  const CameraHome({Key? key, required this.camera}) : super(key: key);

  @override
  State<StatefulWidget> createState() => CameraHomeState();
}

class CameraHomeState extends State<CameraHome> {
  // デバイスのカメラを制御するコントローラ
  late CameraController _cameraController;

  // コントローラーに設定されたカメラを初期化する関数
  late Future<void> _initializeCameraController;

  @override
  void initState() {
    super.initState();

    // ②
    // コントローラを初期化
    _cameraController = CameraController(
        // 使用するカメラをコントローラに設定
        widget.camera,
        // 使用する解像度を設定
        // low : 352x288 on iOS, 240p (320x240) on Android
        // medium : 480p (640x480 on iOS, 720x480 on Android)
        // high : 720p (1280x720)
        // veryHigh : 1080p (1920x1080)
        // ultraHigh : 2160p (3840x2160)
        // max : 利用可能な最大の解像度
        ResolutionPreset.max);

    // ③
    // コントローラーに設定されたカメラを初期化
    _initializeCameraController = _cameraController.initialize();
  }

  // ④
  @override
  void dispose() {
    // ウィジェットが破棄されたタイミングで、カメラのコントローラを破棄する
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      // FutureBuilder(非同期でがめんをこうちくできる)を実装
      body: FutureBuilder<void>(
        future: _initializeCameraController,// 非同期処理
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // カメラの初期化が完了したら、プレビューを表示
            return CameraPreview(_cameraController);
          } else {
            // カメラの初期化中はインジケーターを表示
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.camera_alt),
        // ボタンが押下された際の処理
        onPressed: () async {
          try {
            // ②カメラで画像を撮影する
            final tempImage = await _cameraController.takePicture();

            // ③画像を表示する画面に遷移
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CameraDisplay(imgPath: tempImage.path),
              ),
            );
          } catch (e) {
            print(e);
          }
        },
      ),
    );
  }
}

class CameraDisplay extends StatelessWidget {
  // 表示する画像のパス
  final String imgPath;

  // 画面のコンストラクタ
  const CameraDisplay({Key? key, required this.imgPath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Picture'),
        ),

        body: Column(
          // Imageウィジェットで画像を表示する
          children: [Expanded(child: Image.file(File(imgPath)))],
        )
    );
  }
}

