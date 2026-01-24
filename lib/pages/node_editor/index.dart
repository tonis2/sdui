import 'package:flutter/material.dart';
import 'dart:convert';
import '/components/index.dart';
import 'nodes/form.dart';
import '/models/index.dart';
import 'nodes/image.dart';
import 'nodes/kobold_node.dart';
import 'nodes/folder.dart';
import 'package:hive_ce/hive_ce.dart';
import '/state.dart';

class NodeEditor extends StatefulWidget {
  const NodeEditor({super.key});

  @override
  State<NodeEditor> createState() => _State();
}

class _State extends State<NodeEditor> {
  bool loading = false;
  bool executing = false;
  NodeEditorController controller = NodeEditorController();

  @override
  void initState() {
    _registerNodeTypes();

    Hive.openBox<Config>('configs').then((box) async {
      var configs = box.values.where((item) => item.name == "default");
      if (configs.isNotEmpty) {
        await controller.fromJson(jsonDecode(configs.first.data), context);
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

    super.initState();
  }

  void _registerNodeTypes() {
    // Register nodes with metadata for context menu
    controller.registerNodeType(
      NodeTypeMetadata(
        typeName: (ImageNode).toString(),
        displayName: 'Image',
        description: 'Load and display images',
        icon: Icons.image,
        factory: (json) => ImageNode.fromJson(json),
      ),
    );

    controller.registerNodeType(
      NodeTypeMetadata(
        typeName: (PromptNode).toString(),
        displayName: 'Prompt Config',
        description: 'Configure AI prompts',
        icon: Icons.edit_note,
        factory: (json) => PromptNode.fromJson(json),
      ),
    );

    controller.registerNodeType(
      NodeTypeMetadata(
        typeName: (KoboldNode).toString(),
        displayName: 'Kobold API',
        description: 'Connect to Kobold AI API',
        icon: Icons.smart_toy,
        factory: (json) => KoboldNode.fromJson(json),
      ),
    );

    // Optionally register FolderNode
    controller.registerNodeType(
      NodeTypeMetadata(
        typeName: (FolderNode).toString(),
        displayName: 'Folder',
        description: 'Organize files in folders',
        icon: Icons.folder,
        factory: (json) => FolderNode.fromJson(json),
      ),
    );
  }

  Future<void> saveCanvas() async {
    Box<Config> configs = await Hive.openBox<Config>('configs');
    if (configs.isNotEmpty) {
      configs.putAt(0, Config(name: "default", data: jsonEncode(controller.toJson())));
    } else {
      configs.add(Config(name: "default", data: jsonEncode(controller.toJson())));
    }
  }

  Future<void> executeAll(BuildContext ctx) async {
    if (executing) return;
    setState(() => executing = true);
    try {
      await controller.executeAllEndpoints(ctx);
    } finally {
      setState(() => executing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NodeControls(
      notifier: controller,
      child: Scaffold(
        body: NodeCanvas(controller: controller, size: Size(3000, 3000), zoom: 0.5),
        floatingActionButton: Builder(
          builder: (ctx) => Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: "run",
                onPressed: executing ? null : () => executeAll(ctx),
                backgroundColor: executing ? Colors.grey : null,
                child: executing
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(Icons.play_arrow),
              ),
              SizedBox(height: 10),
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
        ),
      ),
    );
  }
}
