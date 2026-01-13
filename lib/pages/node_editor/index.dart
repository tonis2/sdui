import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import '/components/index.dart';
import '/models/index.dart';
import '/state.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:math';
import 'form.dart';

import 'nodes.dart';

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
    controller.addNodes([
      ImageNode(offset: Offset(200, 400)),
      PromptConfig(offset: Offset(700, 400)),
      KoboldAPI(offset: Offset(1200, 300)),
    ]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return NodeCanvas(size: Size(2000, 2000), controller: controller);
  }
}
