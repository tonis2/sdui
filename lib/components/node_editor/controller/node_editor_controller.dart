import 'dart:collection';
import 'package:flutter/material.dart';
import '../models/index.dart';
import '../utils/node_layout.dart';

/// Controller for managing node editor state
class NodeEditorController extends ChangeNotifier {
  final Map<String, Node> nodes = HashMap();
  List<Connection> connections = [];
  Connection? activeConnection;

  /// Registry with metadata for context menu display
  final Map<String, NodeTypeMetadata> _nodeRegistry = {};

  NodeEditorController();

  /// Unified registration method with metadata
  void registerNodeType(NodeTypeMetadata metadata) {
    _nodeRegistry[metadata.typeName] = metadata;
    notifyListeners();
  }

  /// Get all registered node types for context menu
  List<NodeTypeMetadata> get registeredNodeTypes => _nodeRegistry.values.toList();

  /// Get metadata for a specific node type
  NodeTypeMetadata? getNodeMetadata(String typeName) {
    return _nodeRegistry[typeName];
  }

  /// Convert the entire canvas state to JSON
  Map<String, dynamic> toJson() {
    return {
      "nodes": nodes.values.map((node) => node.toJson()).toList(),
      "connections": connections.map((conn) => conn.toJson()).toList(),
    };
  }

  /// Restore canvas state from JSON
  void fromJson(Map<String, dynamic> json) {
    nodes.clear();
    connections.clear();

    // First pass: create all nodes
    final nodeList = json["nodes"] as List<dynamic>;
    for (final nodeJson in nodeList) {
      final typeName = nodeJson["type"] as String;
      final nodeData = _nodeRegistry[typeName];

      if (nodeData == null) {
        throw Exception("Unknown node type: $typeName. Register it with registerNodeType()");
      }

      final node = nodeData.factory(nodeJson);
      nodes[node.uuid] = node;
    }

    // Second pass: restore connections
    final connList = json["connections"] as List<dynamic>;
    for (final connJson in connList) {
      final connection = Connection.fromJson(connJson, nodes);
      if (connection != null) {
        connections.add(connection);
      }
    }

    notifyListeners();
  }

  /// Clear all nodes and connections
  void clear() {
    nodes.clear();
    connections.clear();
    activeConnection = null;
    notifyListeners();
  }

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
          conn.start = NodeLayout.outputConnectorPosition(node, conn.startIndex);
        } else if (conn.endNode?.uuid == node.uuid && conn.endNode != null) {
          conn.end = NodeLayout.inputConnectorPosition(node, conn.endIndex!);
        }
      }
    }
    notifyListeners();
  }

  void connectNodes(Node startNode, Node endNode, int startIndex, int endIndex) {}

  /// Return connected nodes for the node at output index
  List<Node> outGoingNodes<T>(Node node, int index) {
    List<Node> result = [];
    for (var conn in connections) {
      if (conn.startNode.uuid == node.uuid && conn.startIndex == index && conn.endNode != null) {
        result.add(conn.endNode!);
      }
    }
    return result;
  }

  /// Return nodes connected to input at index
  List<Node> incomingNodes(Node node, int index) {
    List<Node> result = [];
    for (var conn in connections) {
      if (conn.endNode?.uuid == node.uuid && conn.endIndex == index) {
        result.add(conn.startNode);
      }
    }
    return result;
  }

  /// Find node at the given canvas position
  Node? findNodeAtPosition(Offset position) {
    for (var entry in nodes.entries) {
      final node = entry.value;
      final rect = NodeLayout.nodeRect(node);
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

  /// Remove a node and all its connections
  void removeNode(String uuid) {
    nodes.remove(uuid);
    connections.removeWhere((conn) => conn.startNode.uuid == uuid || conn.endNode?.uuid == uuid);
    notifyListeners();
  }

  /// Disconnect all connections from a node
  void disconnectNode(String uuid) {
    connections.removeWhere((conn) => conn.startNode.uuid == uuid || conn.endNode?.uuid == uuid);
    notifyListeners();
  }
}
