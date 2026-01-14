import 'package:flutter/material.dart';
import '/components/index.dart';
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
      ImageNode(offset: Offset(200, 300)),
      ImageNode(offset: Offset(200, 750)),
      PromptConfig(offset: Offset(700, 300)),
      KoboldAPI(offset: Offset(1200, 300)),
    ]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return NodeCanvas.build(controller, Size(3000, 3000), zoom: 0.5);
  }
}
