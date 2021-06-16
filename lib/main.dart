import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:ml_vision/screens/camera_screen.dart';

List<CameraDescription> cameras = [];
Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Camera not found ${e.description}');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Ml vision',
      debugShowCheckedModeBanner: false,
      home: CamScreen(),
    );
  }
}
