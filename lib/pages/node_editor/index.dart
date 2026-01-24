import 'package:flutter/material.dart';
import 'dart:convert';
import '/components/index.dart';
import 'nodes/form.dart';
import '/models/index.dart';
import 'nodes/image.dart';
import 'nodes/kobold_node.dart';
import 'nodes/folder.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:file_picker/file_picker.dart';

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

    Hive.openBox<Config>('configs').then((box) async {
      var defaultConfig = await rootBundle.loadString('assets/defaultConfig.json');
      var configs = box.values.where((item) => item.name == "default");
      if (configs.isNotEmpty) {
        await controller.fromJson(jsonDecode(configs.first.data), context);
      } else {
        await controller.fromJson(jsonDecode(defaultConfig), context);
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
    var data = jsonEncode(controller.toJson());

    if (configs.isNotEmpty) {
      configs.putAt(0, Config(name: "default", data: data));
    } else {
      configs.add(Config(name: "default", data: data));
    }

    await FileSaver.instance.saveFile(
      name: "sdconfig.json",
      mimeType: MimeType.png,
      bytes: Uint8List.fromList(data.codeUnits),
    );
  }

  Future<void> loadConfig() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: .custom,
      dialogTitle: "Pick config file",
      allowedExtensions: ['json'],
    );

    if (result != null) {
      try {
        PlatformFile file = result.files.first;
        String data = String.fromCharCodes(file.bytes!);
        await controller.fromJson(jsonDecode(data), context);
      } catch (err) {
        print("failed to load config ${err.toString()}");
      }
    } else {
      print("canceled");
      // User canceled the picker
    }
  }

  @override
  Widget build(BuildContext context) {
    return NodeControls(
      notifier: controller,
      child: Scaffold(
        body: NodeCanvas(controller: controller, size: Size(3000, 3000), zoom: 0.5),
        floatingActionButton: ListenableBuilder(
          listenable: controller,
          builder: (ctx, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 10,
              children: [
                FloatingActionButton(
                  heroTag: "run",
                  onPressed: () => controller.executeAllEndpoints(ctx),
                  child: Icon(Icons.play_arrow),
                ),
                FloatingActionButton(heroTag: "save", onPressed: saveCanvas, child: Icon(Icons.save)),
                FloatingActionButton(heroTag: "load", onPressed: loadConfig, child: Icon(Icons.folder_open)),
              ],
            );
          },
        ),
      ),
    );
  }
}
