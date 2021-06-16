import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clipboard/clipboard.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({required this.imagePath, Key? key}) : super(key: key);
  final String imagePath;
  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late final String _imagePath;
  late final TextDetector _textDetector;
  Size? _imageSize;
  List<TextElement> _elements = [];

  List<String>? _listEmailStrings;

  Future<void> _getImageSize(File imageFile) async {
    final Completer<Size> completer = Completer<Size>();
    final Image image = Image.file(imageFile);
    image.image
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(
          Size(info.image.width.toDouble(), info.image.height.toDouble()));
    }));

    final Size imageSize = await completer.future;
    setState(() {
      _imageSize = imageSize;
    });
  }

  void _recognizeEmails() async {
    _getImageSize(File(_imagePath));
    final inputImage = InputImage.fromFilePath(_imagePath);
    final text = await _textDetector.processImage(inputImage);

    String pattern =
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$";
    RegExp regEx = RegExp(pattern);

    List<String> emailStrings = [];
    for (TextBlock block in text.blocks) {
      for (TextLine line in block.lines) {
        if (regEx.hasMatch(line.text)) {
          emailStrings.add(line.text);
          for (TextElement element in line.elements) {
            _elements.add(element);
          }
        }
      }
    }

    setState(() {
      _listEmailStrings = emailStrings;
    });
  }

  @override
  void initState() {
    _imagePath = widget.imagePath;
    _textDetector = GoogleMlKit.vision.textDetector();
    _recognizeEmails();
    super.initState();
  }

  @override
  void dispose() {
    _textDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cpysnackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.symmetric(horizontal: 100.0, vertical: 20.0),
      content: Container(
        height: 30.0,
        child: Container(
          child: Center(
            child: Text(
              'Email copied 📋',
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Details'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _imageSize != null
          ? Stack(
              children: [
                Container(
                  width: double.maxFinite,
                  color: Colors.black,
                  child: CustomPaint(
                    foregroundPainter: TextDetectorPainter(
                      _imageSize!,
                      _elements,
                    ),
                    child: AspectRatio(
                      aspectRatio: _imageSize!.aspectRatio,
                      child: Image.file(File(_imagePath)),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Card(
                    elevation: 8,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'Identified Emails: ',
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 120.0,
                            child: SingleChildScrollView(
                                child: _listEmailStrings != null
                                    ? ListView.builder(
                                        shrinkWrap: true,
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: _listEmailStrings!.length,
                                        itemBuilder: (context, index) => Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(_listEmailStrings![index]),
                                            Row(
                                              children: [
                                                IconButton(
                                                    onPressed: () {
                                                      FlutterClipboard.copy(
                                                              _listEmailStrings![
                                                                  index])
                                                          .then((value) =>
                                                              ScaffoldMessenger
                                                                      .of(
                                                                          context)
                                                                  .showSnackBar(
                                                                      cpysnackBar));
                                                    },
                                                    icon:
                                                        const Icon(Icons.copy)),
                                                TextButton(
                                                  onPressed: () async {
                                                    String url =
                                                        'mailto:${_listEmailStrings![index]}';
                                                    if (await canLaunch(url)) {
                                                      await launch(
                                                          'mailto:${_listEmailStrings![index]}'
                                                              .toString());
                                                    } else {
                                                      throw 'Could not launch $url';
                                                    }
                                                  },
                                                  child: const Icon(
                                                    Icons.mail,
                                                    color: Colors.red,
                                                  ),
                                                )
                                              ],
                                            )
                                          ],
                                        ),
                                      )
                                    : const SizedBox()),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            )
          : const SizedBox(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
    );
  }
}

class TextDetectorPainter extends CustomPainter {
  TextDetectorPainter(this.absoluteImageSize, this.elements);
  final Size absoluteImageSize;
  final List<TextElement> elements;
  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;
    Rect scaleRect(TextElement container) {
      return Rect.fromLTRB(
          container.rect.left * scaleX,
          container.rect.top * scaleY,
          container.rect.right * scaleX,
          container.rect.bottom * scaleY);
    }

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.red
      ..strokeWidth = 2.0;

    for (TextElement element in elements) {
      canvas.drawRect(scaleRect(element), paint);
    }
  }

  @override
  bool shouldRepaint(TextDetectorPainter oldDelegate) => true;
}
