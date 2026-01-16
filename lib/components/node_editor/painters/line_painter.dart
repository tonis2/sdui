import 'package:flutter/material.dart';
import '../controller/node_editor_controller.dart';

/// Custom painter for drawing connection lines between nodes
class LinePainter extends CustomPainter {
  final NodeEditorController controller;

  LinePainter({required this.controller});

  final Paint _linePaint = Paint()
    ..color = Colors.black
    ..strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw active connection being dragged
    if (controller.activeConnection != null) {
      canvas.drawLine(controller.activeConnection!.start, controller.activeConnection!.end, _linePaint);
    }

    // Draw all established connections
    for (final conn in controller.connections) {
      canvas.drawLine(conn.start, conn.end, _linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
