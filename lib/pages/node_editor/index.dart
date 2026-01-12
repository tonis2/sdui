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
      id: "prompt",
      label: "Prompt",
      size: Size(300, 400),
      inputs: [
        Input(label: "Image"),
        Input(label: "Mask"),
      ],
      outputs: [Output(label: "Prompt")],
    );

    var image = Node(
      id: "image",
      label: "Image",
      size: Size(300, 300),
      inputs: [],
      outputs: [
        Output(label: "Image"),
        Output(label: "Mask"),
      ],
    );

    var apiNode = Node(
      id: "generate",
      label: "Generate",
      size: Size(200, 200),
      inputs: [Input(label: "Prompt")],
      outputs: [],
    );
    controller.addNodes([image, promptNode, apiNode]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.sizeOf(context);
    return NodeCanvas(size: size, controller: controller);
  }
}
