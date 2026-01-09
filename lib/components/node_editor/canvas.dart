import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:collection';
import 'package:uuid/uuid.dart';
import 'dart:collection';

import 'dart:ui';

class _LinePainter extends CustomPainter {
  final List<Connection> connections;
  final Connection? activeConnection;
  _LinePainter(this.connections, this.activeConnection);

  Paint paintColor = Paint()
    ..color = Colors.black
    ..strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    if (activeConnection != null) {
      canvas.drawLine(activeConnection!.start, activeConnection!.end, paintColor);
    }

    for (var i = 0; i < connections.length; i += 1) {
      Connection conn = connections[i];
      canvas.drawLine(conn.start, conn.end, paintColor);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

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
  final String key;
  final String uuid = Uuid().v4();
  final String label;
  final List<Input> inputs;
  final List<Output> outputs;
  Size size = Size(100, 100);
  Offset offset = Offset(0, 0);

  Node({
    required this.key,
    required this.label,
    required this.inputs,
    required this.outputs,
    this.size = const Size(100, 100),
  });
}

class Connection {
  Offset start;
  Offset end;
  Node startNode;
  Node? endNode;

  Connection({required this.start, required this.end, required this.startNode, this.endNode});
}

class NodeEditorController extends ChangeNotifier {
  final Map<String, Node> nodes = HashMap();
  List<Connection> connections = [];

  NodeEditorController();

  void addNodes(List<Node> items) {
    for (var node in items) {
      nodes[node.key] = node;
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

  Connection? activeConnection;

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

  Offset calcOffset(Offset offset, Size size) {
    return offset - Offset(size.width / 2, 70 + size.height / 2);
  }

  Widget inputRow(Node node) {
    return Column(
      spacing: 10,
      mainAxisAlignment: .center,
      crossAxisAlignment: .center,
      children: node.inputs.map((input) {
        return Tooltip(
          message: input.label,
          child: InkWell(
            onTapDown: (details) {
              if (activeConnection != null) {
                // Make connection between nodes

                var previousConnection = widget.controller.connections.where((conn) {
                  return conn.startNode.uuid == activeConnection!.startNode.uuid &&
                      conn.endNode?.uuid == activeConnection!.endNode!.uuid;
                });

                if (previousConnection.isNotEmpty) return;

                setState(() {
                  widget.controller.connections.add(activeConnection!..endNode = node);
                  activeConnection = null;
                });
              }
            },
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(10)),
            ),
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
          child: InkWell(
            onTapDown: (details) {
              setState(() {
                activeConnection = Connection(
                  start: details.globalPosition + Offset(-10, -80),
                  end: details.globalPosition,
                  startNode: node,
                );
              });
            },
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.sizeOf(context);

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Listener(
        onPointerHover: (event) {
          if (activeConnection != null) {
            setState(() {
              activeConnection?.end = event.localPosition;
            });
          }
        },
        child: Stack(
          children: [
            Listener(
              onPointerDown: (details) {
                if (activeConnection != null) {
                  setState(() {
                    activeConnection = null;
                  });
                }
              },
              child: CustomPaint(
                painter: _LinePainter(widget.controller.connections, activeConnection),
                size: widget.size,
              ),
            ),
            ...widget.controller.nodes.entries.map((item) {
              Node node = item.value;
              return Positioned(
                top: node.offset.dy,
                left: node.offset.dx,
                child: Draggable(
                  maxSimultaneousDrags: 1,
                  onDragUpdate: (DragUpdateDetails details) {
                    activeConnection = null;
                    item.value.offset = calcOffset(details.localPosition, node.size);

                    var previousConnections = widget.controller.connections.where((conn) {
                      return conn.startNode.uuid == node.uuid || conn.endNode?.uuid == node.uuid;
                    });

                    if (previousConnections.isNotEmpty) {
                      for (var conn in previousConnections) {
                        if (conn.startNode.uuid == node.uuid) {
                          conn.start = details.localPosition + Offset(node.size.width / 2, -70);
                        } else if (conn.endNode?.uuid == node.uuid) {
                          conn.end = details.localPosition - Offset(node.size.width / 2, 70);
                        }
                      }
                    }

                    setState(() {});
                  },
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