import 'package:flutter/material.dart';
import 'dart:convert';
import '/components/index.dart';
import 'form.dart';
import '/state.dart';
import '/models/index.dart';
import 'image.dart';
import 'kobold_node.dart';
import 'package:hive_ce/hive_ce.dart';

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

    Hive.openBox<Config>('configs').then((box) {
      var configs = box.values.where((item) => item.name == "default");
      if (configs.isNotEmpty) {
        var config = configs.first;
        controller.fromJson(jsonDecode(config.data));
      } else {
        controller.addNodes([
          ImageNode(offset: Offset(200, 300)),
          ImageNode(offset: Offset(200, 850)),
          PromptNode(offset: Offset(700, 300)),
          KoboldNode(offset: Offset(1300, 300)),
        ]);
      }

      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppState provider = Inherited.of(context)!;
      provider.loadData(context);
    });

    super.initState();
  }

  void _registerNodeTypes() {
    controller.registerNodeType((ImageNode).toString(), (json) => ImageNode.fromJson(json));
    controller.registerNodeType((PromptNode).toString(), (json) => PromptNode.fromJson(json));
    controller.registerNodeType((KoboldNode).toString(), (json) => KoboldNode.fromJson(json));
    controller.registerNodeType((FormNode).toString(), (json) => FormNode.fromJson(json));
    controller.registerNodeType((FormNode).toString(), (json) => FormNode.fromJson(json));
  }

  Future<void> saveCanvas() async {
    final json = controller.toJson();
    Box<Config> configs = await Hive.openBox<Config>('configs');
    configs.putAt(0, Config(name: "default", data: jsonEncode(json)));
    print("Canvas JSON saved:");
  }

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
