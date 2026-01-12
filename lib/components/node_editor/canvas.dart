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
  final String key;
  final Color color;
  final String uuid = const Uuid().v4();

  Input({required this.label, required this.key, this.color = Colors.lightGreen});
}

class Output {
  final String label;
  final String key;
  final Color color;
  final String uuid = Uuid().v4();

  Output({required this.label, required this.key, this.color = Colors.blue});
}

class Node {
  final String key;
  final String uuid = const Uuid().v4();
  final String label;
  final List<Input> inputs;
  final List<Output> outputs;
  final Color color;
  Size size = Size(100, 100);
  Offset offset = Offset(0, 0);

  Node({
    required this.key,
    required this.label,
    required this.inputs,
    required this.outputs,
    this.color = const Color.fromRGBO(128, 186, 215, 0.5),
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

  Connection? activeConnection;

  NodeEditorController();

  set activeConn(Connection connection) {
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
  Size offset;

  NodeCanvas({required this.controller, required this.size, super.key, this.offset = Size.zero});

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
              Expanded(child: Column(children: [])),
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

  Offset calcOffset(Offset offset, Size size) {
    return offset - Offset(size.width / 2, size.height / 2 + widget.offset.height);
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
              if (widget.controller.activeConnection != null) {
                // Make connection between nodes

                var previousConnection = widget.controller.connections.where((conn) {
                  return conn.startNode.uuid == widget.controller.activeConnection!.startNode.uuid &&
                      conn.endNode?.uuid == widget.controller.activeConnection!.endNode!.uuid;
                });

                if (previousConnection.isNotEmpty) return;

                widget.controller.addConnection(widget.controller.activeConnection!..endNode = node);
              } else {
                var previousConnection = widget.controller.connections.where((conn) => conn.endNode?.uuid == node.uuid);

                // Handle already made connection, when click you can remove already made connection
                if (previousConnection.isNotEmpty) {
                  var connection = previousConnection.first;

                  widget.controller.removeConnection(connection);

                  widget.controller.activeConn = Connection(
                    start:
                        connection.startNode.offset +
                        Offset(connection.startNode.size.width, (connection.startNode.size.height / 2) + 40),
                    end: details.globalPosition,
                    startNode: connection.startNode,
                  );
                }
              }
            },
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(color: input.color, borderRadius: BorderRadius.circular(10)),
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
              widget.controller.activeConn = Connection(
                start: details.globalPosition + Offset(-10, -10 - widget.offset.height),
                end: details.globalPosition,
                startNode: node,
              );
            },
            child: Container(
              width: 15,
              height: 15,
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
                  onDragUpdate: (DragUpdateDetails details) {
                    widget.controller.removeActive();

                    item.value.offset = calcOffset(details.localPosition, node.size);

                    var previousConnections = widget.controller.connections.where((conn) {
                      return conn.startNode.uuid == node.uuid || conn.endNode?.uuid == node.uuid;
                    });

                    if (previousConnections.isNotEmpty) {
                      for (var conn in previousConnections) {
                        if (conn.startNode.uuid == node.uuid) {
                          conn.start = details.localPosition + Offset(node.size.width / 2, -70 + 40);
                        } else if (conn.endNode?.uuid == node.uuid) {
                          conn.end = details.localPosition - Offset(node.size.width / 2, 70 - 40);
                        }
                      }
                    }

                    setState(() {});
                  },
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