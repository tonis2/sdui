import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import '/components/index.dart';
import '/models/index.dart';
import '/state.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:math';

class NodeEditor extends StatefulWidget {
  const NodeEditor({super.key});

  @override
  State<NodeEditor> createState() => _State();
}

class _State extends State<NodeEditor> {
  bool loading = false;
  NodeEditorController controller = NodeEditorController();

  @override
  void initState() {
    // controller.addNodes([NodeView(controller: controller)]);

    var promptNode = Node(
      key: "prompt",
      label: "Prompt",
      size: Size(200, 300),
      inputs: [
        Input(label: "Image", key: "image"),
        Input(label: "Mask", key: "mask"),
      ],
      outputs: [Output(label: "Prompt", key: "prompt")],
    );
    var apiNode = Node(
      key: "generate",
      label: "Generate",
      size: Size(200, 200),
      inputs: [Input(label: "Prompt", key: "prompt")],
      outputs: [],
    );
    controller.addNodes([promptNode, apiNode]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.sizeOf(context);
    return NodeCanvas(size: size, controller: controller);
  }
}
