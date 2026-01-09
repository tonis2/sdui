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

    controller.addNodes([Node(id: "prompt", label: "Prompt")]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.sizeOf(context);
    return NodeCanvas(size: size, controller: controller);
  }
}
