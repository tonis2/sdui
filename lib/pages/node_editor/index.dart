import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:easy_nodes/index.dart';
import '/models/index.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle, LogicalKeyboardKey;
import 'package:file_picker/file_picker.dart';
import '/state.dart';

class NodeEditor extends StatefulWidget {
  const NodeEditor({super.key});

  @override
  State<NodeEditor> createState() => _State();
}

class _State extends State<NodeEditor> {
  bool loading = false;

  @override
  void initState() {
    Hive.openBox<Config>('configs').then((box) async {
      AppState provider = Inherited.of(context)!;
      if (provider.nodeController.nodes.isNotEmpty) return;

      var defaultConfig = await rootBundle.loadString('assets/defaultConfig.json');
      var configs = box.values.where((item) => item.name == "default");
      if (configs.isNotEmpty) {
        await provider.nodeController.fromJson(jsonDecode(configs.first.data), context);
      } else {
        await provider.nodeController.fromJson(jsonDecode(defaultConfig), context);
      }

      setState(() {});
    });

    super.initState();
  }

  Future<void> saveCanvas({bool saveAsFile = false}) async {
    AppState provider = Inherited.of(context)!;
    Box<Config> configs = await Hive.openBox<Config>('configs');
    var data = jsonEncode(provider.nodeController.toJson());

    if (configs.isNotEmpty) {
      configs.putAt(0, Config(name: "default", data: data));
    } else {
      configs.add(Config(name: "default", data: data));
    }

    if (saveAsFile) {
      await FileSaver.instance.saveFile(
        name: "sdconfig.json",
        mimeType: MimeType.png,
        bytes: Uint8List.fromList(data.codeUnits),
      );
    }
  }

  Future<void> loadConfig() async {
    AppState provider = Inherited.of(context)!;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: .custom,
      dialogTitle: "Pick config file",
      allowedExtensions: ['json'],
    );

    if (result != null) {
      try {
        PlatformFile file = result.files.first;
        String data = String.fromCharCodes(file.bytes!);
        await provider.nodeController.fromJson(jsonDecode(data), context);
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
    AppState provider = Inherited.of(context)!;
    return NodeControls(
      notifier: provider.nodeController,
      child: CallbackShortcuts(
        bindings: {SingleActivator(LogicalKeyboardKey.keyS, control: true): saveCanvas},
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: NodeCanvas(controller: provider.nodeController, size: Size(3000, 3000), zoom: 0.5),
            floatingActionButton: Builder(
              builder: (ctx) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 10,
                  children: [
                    FloatingActionButton(
                      heroTag: "run",
                      onPressed: () => provider.nodeController.executeAllEndpoints(ctx),
                      child: Icon(Icons.play_arrow),
                    ),
                    FloatingActionButton(
                      heroTag: "save",
                      onPressed: () => saveCanvas(saveAsFile: true),
                      child: Icon(Icons.save),
                    ),
                    FloatingActionButton(heroTag: "load", onPressed: loadConfig, child: Icon(Icons.folder_open)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
