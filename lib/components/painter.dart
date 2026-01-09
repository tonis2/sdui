import 'package:flutter/material.dart';
import 'dart:typed_data';
import '/models/index.dart';
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
    //canvas.drawRect(Rect.fromLTRB(0, 0, size.width, size.height), Paint()..color = Colors.black);

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

class CanvasController extends ChangeNotifier {
  List<DrawingPoint?> points = [];
  Color paintColor;
  double strokeWidth;
  BackgroundImage? backgroundLayer;
  CustomPainter? canvas;

  CanvasController({this.paintColor = const Color.fromARGB(255, 255, 255, 255), this.strokeWidth = 90.0}) {
    canvas = MyPainter(points);
  }

  void recreateCanvas() {
    canvas = MyPainter(points);
  }

  void clear() {
    points.clear();
    recreateCanvas();
    backgroundLayer = null;
    notifyListeners();
  }

  void addPoint(DrawingPoint? point) {
    points.add(point);
    recreateCanvas();
    notifyListeners();
  }

  void resize(int width, int height) {
    backgroundLayer?.width = width;
    backgroundLayer?.height = height;

    recreateCanvas();
    notifyListeners();
  }

  // void setStrokeWidth(double value) {
  //   strokeWidth = value;
  //   recreateCanvas();
  //   notifyListeners();
  // }

  void setBackground(BackgroundImage image) {
    backgroundLayer = image;

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

  Size size;

  CanvasPainter({required this.controller, required this.size, super.key});

  @override
  State<CanvasPainter> createState() => _State();
}

class _State extends State<CanvasPainter> {
  void updateCanvas() {
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
    return SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            var offset = renderBox.globalToLocal(details.globalPosition);

            // over the box borders
            if (offset.dx < 0 || offset.dy < 0) return;

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
        onPanEnd: (details) => widget.controller.addPoint(null),
        child: Stack(
          children: [
            if (widget.controller.backgroundLayer != null)
              Image(
                image: ResizeImage(
                  MemoryImage(widget.controller.backgroundLayer!.data),
                  width: widget.controller.backgroundLayer!.width,
                  height: widget.controller.backgroundLayer!.height,
                ),
              ),
            CustomPaint(painter: widget.controller.canvas, size: widget.size),
          ],
        ),
      ),
    );
  }
}
