import 'package:flutter/material.dart';
import 'dart:collection';

import 'dart:ui';

class Input {
  final String label;
  final String key;

  const Input({required this.label, required this.key});
}

class Output {
  final String label;
  final String key;

  const Output({required this.label, required this.key});
}

class Node {
  final String id;
  final String label;
  final List<Input> inputs;
  final List<Output> outputs;
  Size size = Size(100, 100);
  Offset offset = Offset(0, 0);

  Node({
    required this.id,
    required this.label,
    required this.inputs,
    required this.outputs,
    this.size = const Size(100, 100),
  });
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

  Widget inputRow(Node node) {
    return Column(
      spacing: 10,
      mainAxisAlignment: .center,
      crossAxisAlignment: .center,
      children: node.inputs.map((input) {
        return Tooltip(
          message: input.label,
          child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(10)),
          ),
        );
      }).toList(),
    );
  }

  Widget outputRow(Node node) {
    return Column(
      spacing: 10,
      mainAxisAlignment: .center,
      crossAxisAlignment: .center,
      children: node.outputs.map((input) {
        return Tooltip(
          message: input.label,
          child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.sizeOf(context);
    var menuOffset = 70;
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
                  item.value.offset =
                      details.localPosition - Offset(node.size.width / 2, menuOffset + node.size.height / 2);
                  setState(() {});
                },
                onDragStarted: () {},
                onDragEnd: (details) {},
                feedback: Container(decoration: BoxDecoration(color: Colors.red)),
                child: Container(
                  width: node.size.width,
                  height: node.size.height,
                  decoration: BoxDecoration(color: Colors.green),
                  child: Row(
                    children: [
                      SizedBox(width: 20, height: size.height, child: inputRow(node)),
                      Expanded(child: Column(children: [])),
                      SizedBox(width: 20, height: size.height, child: outputRow(node)),
                    ],
                  ),
                ),
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