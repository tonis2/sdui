import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:collection';
import 'package:uuid/uuid.dart';
import 'dart:collection';

import 'dart:ui';

class _LinePainter extends CustomPainter {
  final NodeEditorController controller;

  _LinePainter({required this.controller});

  Paint paintColor = Paint()
    ..color = Colors.black
    ..strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    if (controller.activeConnection != null) {
      canvas.drawLine(controller.activeConnection!.start, controller.activeConnection!.end, paintColor);
    }

    for (var i = 0; i < controller.connections.length; i += 1) {
      Connection conn = controller.connections[i];
      canvas.drawLine(conn.start, conn.end, paintColor);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Input {
  final String label;
  final String? key;
  final Color color;
  final String uuid = "";

  const Input({required this.label, this.key, this.color = Colors.lightGreen});
}

class Output {
  final String label;
  final String? key;
  final Color color;
  final String uuid = "";

  const Output({required this.label, this.key, this.color = Colors.blue});
}

abstract class Node extends StatelessWidget {
  final String? id;
  final String label;
  final List<Input> inputs;
  final List<Output> outputs;
  final Color color;
  final String uuid = Uuid().v4();
  final Size size;
  Offset offset;

  Offset calcOffset(Offset offset) {
    return offset - Offset(size.width / 2, size.height / 2);
  }

  Node({
    this.id,
    required this.label,
    required this.inputs,
    required this.outputs,
    this.offset = const Offset(0, 0),
    this.color = const Color.fromRGBO(128, 186, 215, 0.5),
    this.size = const Size(100, 100),
    super.key,
  });

  void execute(NodeEditorController controller) {}

  @override
  Widget build(BuildContext context) => SizedBox();
}

class Connection {
  Offset start;
  Offset end;
  Node startNode;
  int startIndex;
  Node? endNode;
  int? endIndex;

  Connection({
    required this.start,
    required this.end,
    required this.startNode,
    required this.startIndex,
    this.endIndex,
    this.endNode,
  });
}

class NodeEditorController extends ChangeNotifier {
  final Map<String, Node> nodes = HashMap();
  List<Connection> connections = [];

  Connection? activeConnection;

  NodeEditorController();

  void setActiveConnection(Connection connection) {
    activeConnection = connection;
    notifyListeners();
  }

  void addConnection(Connection connection) {
    connections.add(connection);
    activeConnection = null;
    notifyListeners();
  }

  void removeConnection(Connection connection) {
    connections.remove(connection);
    activeConnection = null;
    notifyListeners();
  }

  void removeActive() {
    if (activeConnection != null) {
      activeConnection = null;
      notifyListeners();
    }
  }

  void setNodePosition(Offset offset, String uuid) {
    Node? node = nodes[uuid];

    if (node != null) {
      activeConnection = null;
      offset = node.calcOffset(offset);
      nodes[uuid]?.offset = offset;
      var previousConnections = connections.where(
        (conn) => conn.startNode.uuid == node.uuid || conn.endNode?.uuid == node.uuid,
      );

      if (previousConnections.isNotEmpty) {
        for (var conn in previousConnections) {
          if (conn.startNode.uuid == node.uuid) {
            double indexOffset = (conn.startIndex * 40);
            conn.start = offset + Offset(node.size.width, 45 + indexOffset);
          } else if (conn.endNode?.uuid == node.uuid && conn.endNode != null) {
            double indexOffset = (conn.endIndex! * 40);
            conn.end = offset + Offset(0, 45 + indexOffset);
          }
        }
      }
      notifyListeners();
    }
  }

  void connectNodes(Node startNode, Node endNode, int startIndex, int endInded) {}

  // Return connected nodes for the node at index
  List<Node> connectedNodes(Node node, int index) {
    List<Node> nodes = [];
    for (var conn in connections) {
      if (conn.startNode.uuid == node.uuid && conn.startIndex == index && conn.endNode != null) {
        nodes.add(conn.endNode!);
      } else if (conn.endNode?.uuid == node.uuid && conn.endIndex == index) {
        nodes.add(conn.startNode);
      }
    }

    return nodes;
  }

  void addNodes(List<Node> items) {
    for (var node in items) {
      nodes[node.uuid] = node;
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

  Widget nodeBase(Node node) {
    ThemeData theme = Theme.of(context);

    return Container(
      width: node.size.width,
      height: node.size.height + 40,
      decoration: BoxDecoration(color: theme.colorScheme.secondary, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Container(
            height: 40,
            width: node.size.width,
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: node.color,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            child: Text(node.label, style: theme.textTheme.bodyLarge),
          ),
          Row(
            children: [
              SizedBox(width: 20, height: node.size.height, child: inputRow(node)),
              Expanded(child: node.build(context)),
              SizedBox(width: 20, height: node.size.height, child: outputRow(node)),
            ],
          ),
        ],
      ),
    );
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
      spacing: 15,
      mainAxisAlignment: .start,
      crossAxisAlignment: .center,
      children: node.inputs.map((input) {
        int index = node.inputs.indexOf(input);

        return Tooltip(
          message: input.label,
          child: InkWell(
            onTapDown: (details) {
              if (widget.controller.activeConnection != null) {
                // Make connection between nodes

                //TODO: broken
                // var previousConnection = widget.controller.connections.where((conn) {
                //   return conn.startNode.uuid == widget.controller.activeConnection!.startNode.uuid ||
                //       conn.endNode?.uuid == widget.controller.activeConnection!.endNode!.uuid;
                // });

                // if (previousConnection.isNotEmpty) return;

                widget.controller.addConnection(
                  widget.controller.activeConnection!
                    ..endNode = node
                    ..endIndex = index,
                );
              } else {
                var previousConnection = widget.controller.connections.where((conn) => conn.endNode?.uuid == node.uuid);

                // Handle already made connection, when click you can remove already made connection
                if (previousConnection.isNotEmpty) {
                  var connection = previousConnection.first;

                  widget.controller.removeConnection(connection);

                  widget.controller.setActiveConnection(
                    Connection(
                      start:
                          connection.startNode.offset +
                          Offset(connection.startNode.size.width, 45 + connection.startIndex * 40),
                      end: details.globalPosition,
                      startNode: connection.startNode,
                      startIndex: connection.startIndex,
                      endIndex: index,
                    ),
                  );
                }
              }
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(color: input.color, borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget outputRow(Node node) {
    return Column(
      spacing: 15,
      mainAxisAlignment: .start,
      crossAxisAlignment: .center,
      children: node.outputs.map((input) {
        int index = node.outputs.indexOf(input);

        double indexOffset = index > 0 ? index * 40 : 0;

        Offset offset = node.offset + Offset(node.size.width, 45 + indexOffset);

        return Tooltip(
          message: input.label,
          child: InkWell(
            onTapDown: (details) {
              widget.controller.setActiveConnection(
                Connection(start: offset, end: offset, startNode: node, startIndex: index),
              );
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(color: input.color, borderRadius: BorderRadius.circular(10)),
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
          if (widget.controller.activeConnection != null) {
            setState(() {
              widget.controller.activeConnection?.end = event.localPosition;
            });
          }
        },
        child: Stack(
          children: [
            Listener(
              onPointerDown: (details) {
                widget.controller.removeActive();
              },
              child: CustomPaint(
                painter: _LinePainter(controller: widget.controller),
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
                  onDragUpdate: (DragUpdateDetails details) =>
                      widget.controller.setNodePosition(details.localPosition, node.uuid),
                  feedback: Container(decoration: BoxDecoration(color: Colors.red)),
                  child: nodeBase(node),
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