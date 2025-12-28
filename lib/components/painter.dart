import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui';

class DrawingPoint {
  final Offset? offset;
  final Paint paint;

  DrawingPoint(this.offset, this.paint);
}

class MyPainter extends CustomPainter {
  final List<DrawingPoint?> points;

  MyPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        // Draw a line between two consecutive points
        canvas.drawLine(points[i]!.offset!, points[i + 1]!.offset!, points[i]!.paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BackgroundImage {
  int width;
  int height;
  Uint8List data;
  String? mimeType;
  String? name;

  BackgroundImage({required this.width, required this.height, required this.data, this.name, this.mimeType});

  factory BackgroundImage.fromJson(Map<String, dynamic> json) {
    return BackgroundImage(
      width: json["width"],
      height: json["height"],
      data: json["data"],
      mimeType: json["mimeType"],
      name: json["name"],
    );
  }

  Map<String, dynamic> toJson() {
    return {"width": width, "height": height, "data": data, "mimeType": mimeType, "name": name};
  }
}

class CanvasController extends ChangeNotifier {
  List<DrawingPoint?> points = [];
  Color paintColor;
  double strokeWidth;
  List<BackgroundImage> backgroundLayers = [];
  CustomPainter? canvas;

  CanvasController({this.paintColor = const Color.fromRGBO(255, 254, 254, 0.213), this.strokeWidth = 25.0}) {
    canvas = MyPainter(points);
  }

  void recreateCanvas() {
    canvas = MyPainter(points);
  }

  void clear() {
    points.clear();
    recreateCanvas();
    notifyListeners();
  }

  void addPoint(DrawingPoint? point) {
    points.add(point);
    recreateCanvas();
    notifyListeners();
  }

  void resize(int width, int height) {
    for (var image in backgroundLayers) {
      image.width = width;
      image.height = height;
    }

    recreateCanvas();
    notifyListeners();
  }

  // void setStrokeWidth(double value) {
  //   strokeWidth = value;
  //   recreateCanvas();
  //   notifyListeners();
  // }

  void addBackground(BackgroundImage image) {
    backgroundLayers.add(image);
    recreateCanvas();
    notifyListeners();
  }

  void setBackground(BackgroundImage image) {
    if (backgroundLayers.isEmpty) {
      backgroundLayers.add(image);
    } else {
      backgroundLayers[0] = image;
    }

    points.clear();
    recreateCanvas();
    notifyListeners();
  }

  Future<Uint8List?> getMaskImage(Size size, {ImageByteFormat format = .png, double? pixelRatio}) async {
    PictureRecorder recorder = PictureRecorder();
    Canvas recordCanvas = Canvas(recorder);

    if (pixelRatio != null) recordCanvas.scale(pixelRatio);
    canvas?.paint(recordCanvas, size);

    var renderedImage = await recorder.endRecording().toImage(size.width.floor(), size.height.floor());

    var bytes = await renderedImage.toByteData(format: format);
    return bytes?.buffer.asUint8List();
  }
}

class CanvasPainter extends StatefulWidget {
  CanvasController controller;

  CanvasPainter({required this.controller, super.key});

  @override
  State<CanvasPainter> createState() => _State();
}

class _State extends State<CanvasPainter> {
  updateCanvas() {
    setState(() {});
  }

  @override
  void initState() {
    widget.controller.addListener(updateCanvas);
    super.initState();
  }

  @override
  void dispose() {
    widget.controller.removeListener(updateCanvas);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.sizeOf(context);

    return SizedBox(
      width: size.width,
      height: size.height,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            var offset = renderBox.globalToLocal(details.globalPosition);

            // over the box borders
            if (offset.dx < 0 || offset.dy < 0 || offset.dx > size.width || offset.dy > size.height) return;

            widget.controller.addPoint(
              DrawingPoint(
                offset,
                Paint()
                  ..color = widget.controller.paintColor
                  ..strokeCap = StrokeCap.round
                  ..strokeWidth = widget.controller.strokeWidth,
              ),
            );
          });
        },
        onPanEnd: (details) {
          widget.controller.addPoint(null); // Add a null to signify the end of a stroke
        },
        child: Stack(
          children: [
            // 1. The Background Image
            ...widget.controller.backgroundLayers.map(
              (img) => Align(
                alignment: AlignmentGeometry.center,
                child: Image(
                  image: ResizeImage(MemoryImage(img.data), width: img.width, height: img.height),
                ),
              ),
            ),
            // 2. The CustomPaint layer
            CustomPaint(painter: widget.controller.canvas, size: size),
          ],
        ),
      ),
    );
  }
}
