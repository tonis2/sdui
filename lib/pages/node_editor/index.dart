import 'package:flutter/material.dart';
import 'dart:convert';
import '/components/index.dart';
import 'form.dart';
import '/state.dart';
import 'image.dart';
import 'kobold_node.dart';

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
    _registerNodeTypes();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppState provider = Inherited.of(context)!;
      provider.loadData(context);
    });

    controller.addNodes([
      ImageNode(offset: Offset(200, 300)),
      ImageNode(offset: Offset(200, 850)),
      PromptNode(offset: Offset(700, 300)),
      KoboldNode(offset: Offset(1300, 300)),
    ]);
    super.initState();
  }

  void _registerNodeTypes() {
    controller.registerNodeType("ImageNode", (json) => ImageNode.fromJson(json));
    controller.registerNodeType("PromptNode", (json) => PromptNode.fromJson(json));
    controller.registerNodeType("KoboldNode", (json) => KoboldNode.fromJson(json));
    controller.registerNodeType("FormNode", (json) => FormNode.fromJson(json));
  }

  Future<void> saveCanvas() async {
    final json = controller.toJson();
    final jsonString = jsonEncode(json);
    print("Canvas JSON saved:");
    print(jsonString);
    // TODO: Save to file or storage
  }

  Future<void> loadCanvas(String jsonString) async {
    final json = jsonDecode(jsonString);
    controller.fromJson(json);
  }

  //   if (provider?.images == null) {
  //   provider?.loadData(context, "test");
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NodeCanvas.build(controller, Size(3000, 3000), zoom: 0.5),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(heroTag: "save", onPressed: saveCanvas, child: Icon(Icons.save)),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "load",
            onPressed: () {
              // TODO: Load from file or storage
              print("Load button pressed - implement file picker");
            },
            child: Icon(Icons.folder_open),
          ),
        ],
      ),
    );
  }
}
