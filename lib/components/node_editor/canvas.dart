import 'package:flutter/material.dart';
import 'dart:collection';

import 'dart:ui';

class Node {
  String id;
  String label;
  Offset offset = Offset(0, 0);

  Node({required this.id, required this.label});
}

class NodeEditorController extends ChangeNotifier {
  // List<Node> nodes = [];
  final Map<String, Node> nodes = HashMap();
  NodeEditorController();

  void addNodes(List<Node> items) {
    for (var node in items) {
      nodes[node.id] = node;
    }

    notifyListeners();
  }
}

class NodeCanvas extends StatefulWidget {
  NodeEditorController controller;

  Size size;

  NodeCanvas({required this.controller, required this.size, super.key});

  @override
  State<NodeCanvas> createState() => _State();
}

class _State extends State<NodeCanvas> {
  final TransformationController _transformationController = TransformationController();
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
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.sizeOf(context);
    return Container(
      decoration: BoxDecoration(color: Colors.orange),
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          ...widget.controller.nodes.entries.map((item) {
            Node node = item.value;
            return Positioned(
              top: node.offset.dy,
              left: node.offset.dx,
              child: Draggable(
                maxSimultaneousDrags: 1,
                onDragUpdate: (DragUpdateDetails details) {
                  item.value.offset = details.localPosition - Offset(50, 70 + 50);
                  setState(() {});
                },
                onDragStarted: () {},
                onDragEnd: (details) {
                  // item.value.offset = details.offset;
                  // setState(() {});
                },

                feedback: Container(decoration: BoxDecoration(color: Colors.red)),
                child: Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.green)),
              ),
            );
          }),
        ],
      ),
    );
  }
}


// InteractiveViewer(
//         transformationController: _transformationController,
//         boundaryMargin: const EdgeInsets.all(20.0),
//         minScale: 0.1,
//         maxScale: 1.6,
//         child: Expanded(
//           child: Stack(
//             children: [
//               ...widget.controller.nodes.entries.map((item) {
//                 Node node = item.value;
//                 return Positioned(
//                   top: node.offset.dy,
//                   left: node.offset.dx,
//                   child: Draggable(
//                     onDragEnd: (details) {
//                       item.value.offset = details.offset;
//                       setState(() {});
//                     },
//                     feedback: Container(decoration: BoxDecoration(color: Colors.red)),
//                     child: Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.green)),
//                   ),
//                 );
//               }),
//             ],
//           ),
//         ),
//       )