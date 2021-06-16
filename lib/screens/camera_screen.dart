import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ml_vision/main.dart';

import 'details_screen.dart';

class CamScreen extends StatefulWidget {
  const CamScreen({Key? key}) : super(key: key);

  @override
  State<CamScreen> createState() => _CamScreenState();
}

class _CamScreenState extends State<CamScreen> {
  late final CameraController _controller;
  //initialize camera
  void _initializeCam() async {
    final CameraController cameraController =
        CameraController(cameras[0], ResolutionPreset.high);
    _controller = cameraController;
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  Future<String?> _takePic() async {
    if (!_controller.value.isInitialized) {
      print('Controller not initialized');
      return null;
    }
    String? imagePath;
    if (_controller.value.isTakingPicture) {
      print('Processing...');
      return null;
    }

    try {
      _controller.setFlashMode(FlashMode.off);
      final XFile file = await _controller.takePicture();
      imagePath = file.path;
    } on CameraException catch (e) {
      print('Camera Exception: $e');
      return null;
    }

    return imagePath;
  }

  @override
  void initState() {
    _initializeCam();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('ML Vision'),
          elevation: 0,
          centerTitle: true,
        ),
        body: _controller.value.isInitialized
            ? Stack(
                children: [
                  Center(child: CameraPreview(_controller)),
                  Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Container(
                      alignment: Alignment.bottomCenter,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.camera_sharp),
                        label: Text('Capture'),
                        onPressed: () async {
                          await _takePic().then((String? path) {
                            if (path != null) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => DetailsScreen(
                                            imagePath: path,
                                          )));
                            } else {
                              print('Image path not found!');
                            }
                          });
                        },
                      ),
                    ),
                  )
                ],
              )
            : Center(
                child: Container(
                  child: Text('Enable Camera permissions'),
                ),
              ));
  }
}
