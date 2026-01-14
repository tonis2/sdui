import 'package:flutter/material.dart';
import 'dart:collection';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart' as vector;

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

  Future<dynamic> execute(BuildContext context) async => Future.value();

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

class NodeControls extends InheritedNotifier<NodeEditorController> {
  const NodeControls({required super.child, super.key, required super.notifier});
  static NodeEditorController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NodeControls>()?.notifier;

  @override
  bool updateShouldNotify(InheritedNotifier<NodeEditorController> oldWidget) => true;
}

class NodeEditorController extends ChangeNotifier {
  final Map<String, Node> nodes = HashMap();
  List<Connection> connections = [];

  Connection? activeConnection;

  NodeEditorController();

  void requestUpdate(String uuid) {
    notifyListeners();
  }

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

  void setNodePosition(Offset offset, Node node) {
    activeConnection = null;
    node.offset = offset;

    var previousConnections = connections.where(
      (conn) => conn.startNode.uuid == node.uuid || conn.endNode?.uuid == node.uuid,
    );

    if (previousConnections.isNotEmpty) {
      for (var conn in previousConnections) {
        if (conn.startNode.uuid == node.uuid) {
          double indexOffset = conn.startIndex > 0 ? conn.startIndex * headerOffset - 5 : nodeOffset / 2;
          conn.start = offset + Offset(node.size.width, headerOffset + nodeOffset + indexOffset);
        } else if (conn.endNode?.uuid == node.uuid && conn.endNode != null) {
          double indexOffset = conn.endIndex! > 0 ? conn.endIndex! * headerOffset - 5 : nodeOffset / 2;
          conn.end = offset + Offset(0, headerOffset + nodeOffset + indexOffset);
        }
      }
    }
    notifyListeners();
  }

  void connectNodes(Node startNode, Node endNode, int startIndex, int endInded) {}

  // Return connected nodes for the node at index
  List<Node> outGoingNodes<T>(Node node, int index) {
    List<Node> nodes = [];
    for (var conn in connections) {
      if (conn.startNode.uuid == node.uuid && conn.startIndex == index && conn.endNode != null) {
        nodes.add(conn.endNode!);
      }
    }
    return nodes;
  }

  List<Node> incomingNodes<T>(Node node, int index) {
    List<Node> nodes = [];
    for (var conn in connections) {
      if (conn.endNode?.uuid == node.uuid && conn.endIndex == index) {
        nodes.add(conn.startNode);
      }
    }
    return nodes;
  }

  Node? _findNodeAtPosition(Offset position) {
    // Find node at the given canvas position
    for (var entry in nodes.entries) {
      final node = entry.value;
      final rect = Rect.fromLTWH(
        node.offset.dx,
        node.offset.dy,
        node.size.width,
        node.size.height + headerOffset, // Include header
      );
      if (rect.contains(position)) {
        return node;
      }
    }
    return null;
  }

  void addNodes(List<Node> items) {
    for (var node in items) {
      nodes[node.uuid] = node;
    }

    notifyListeners();
  }
}

double headerOffset = 50;
double nodeOffset = 20;

class NodeCanvas extends StatefulWidget {
  static Widget build(NodeEditorController controller, Size size, {double zoom = 1.0}) {
    return NodeControls(
      notifier: controller,
      child: NodeCanvas(size: size, controller: controller, zoom: zoom),
    );
  }

  NodeEditorController controller;
  Size size;
  double zoom;
  NodeCanvas({required this.controller, required this.size, this.zoom = 1.0, super.key});

  @override
  State<NodeCanvas> createState() => _State();
}

class _State extends State<NodeCanvas> {
  final TransformationController _transformationController = TransformationController();
  String? _draggingNodeId;
  Offset _lastDragPosition = Offset.zero;

  void updateCanvas() {
    setState(() {});
  }

  Widget nodeBase(Node node) {
    ThemeData theme = Theme.of(context);

    return Container(
      width: node.size.width,
      height: node.size.height + headerOffset + nodeOffset,
      decoration: BoxDecoration(color: theme.colorScheme.secondary, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Container(
            height: headerOffset,
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
              Container(
                margin: EdgeInsets.only(top: nodeOffset, right: 5),
                width: 20,
                height: node.size.height,
                child: inputRow(node),
              ),
              Expanded(child: node.build(context)),
              Container(
                margin: EdgeInsets.only(top: nodeOffset, left: 5),
                width: 20,
                height: node.size.height,
                child: outputRow(node),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    widget.controller.addListener(updateCanvas);
    _transformationController.value = Matrix4.identity()
      ..scaleByVector3(vector.Vector3(widget.zoom, widget.zoom, widget.zoom));
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

                  double indexOffset = index > 0
                      ? (index * headerOffset) + headerOffset + nodeOffset - 5
                      : headerOffset + nodeOffset + 10;

                  widget.controller.removeConnection(connection);
                  widget.controller.setActiveConnection(
                    Connection(
                      start: connection.startNode.offset + Offset(connection.startNode.size.width, indexOffset),
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
        double indexOffset = index > 0
            ? (index * headerOffset) + headerOffset + nodeOffset - 5
            : headerOffset + nodeOffset + 10;
        Offset offset = node.offset + Offset(node.size.width, indexOffset);

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

  Offset _transformPosition(Offset screenPosition) {
    // Transform screen coordinates to canvas coordinates
    final Matrix4 transform = _transformationController.value;
    final Matrix4 invertedTransform = Matrix4.inverted(transform);
    final vector.Vector3 position = invertedTransform.transform3(
      vector.Vector3(screenPosition.dx, screenPosition.dy, 0),
    );
    return Offset(position.x, position.y);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        final canvasPosition = _transformPosition(event.localPosition);
        final node = widget.controller._findNodeAtPosition(canvasPosition);

        if (node != null) {
          setState(() {
            _draggingNodeId = node.uuid;
            _lastDragPosition = canvasPosition;
          });
        } else {
          widget.controller.removeActive();
        }
      },
      onPointerHover: (event) {
        if (widget.controller.activeConnection != null) {
          final canvasPosition = _transformPosition(event.localPosition);
          setState(() {
            widget.controller.activeConnection?.end = canvasPosition;
          });
        }
      },
      onPointerMove: (details) {
        final canvasPosition = _transformPosition(details.localPosition);

        if (_draggingNodeId != null) {
          // Dragging a node
          final delta = canvasPosition - _lastDragPosition;
          final node = widget.controller.nodes[_draggingNodeId];

          if (node != null) {
            widget.controller.setNodePosition(Offset(node.offset.dx + delta.dx, node.offset.dy + delta.dy), node);
            _lastDragPosition = canvasPosition;
            setState(() {});
          }
        } else if (details.buttons == 4) {
          // Middle mouse button - pan the view
          final currentMatrix = _transformationController.value;
          final currentScale = currentMatrix.getMaxScaleOnAxis();
          final currentTranslation = currentMatrix.getTranslation();

          final newTranslation = currentTranslation + vector.Vector3(details.delta.dx, details.delta.dy, 0);

          _transformationController.value = Matrix4.identity()
            ..translateByVector3(newTranslation)
            ..scaleByVector3(vector.Vector3(currentScale, currentScale, currentScale));
        }
      },
      onPointerUp: (details) {
        setState(() {
          _draggingNodeId = null;
        });
      },
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.1,
        maxScale: 10,
        panEnabled: false,
        scaleEnabled: true,
        boundaryMargin: EdgeInsets.all(double.infinity),
        constrained: false,
        // onInteractionStart: (details) {},
        child: SizedBox(
          width: widget.size.width,
          height: widget.size.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                painter: _LinePainter(controller: widget.controller),
                size: Size(widget.size.width, widget.size.height),
              ),
              ...widget.controller.nodes.entries.map((item) {
                Node node = item.value;
                return Positioned(top: node.offset.dy, left: node.offset.dx, child: nodeBase(node));
              }),
            ],
          ),
        ),
      ),
    );
  }
}
