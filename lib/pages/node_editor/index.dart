import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:easy_nodes/index.dart';
import '/models/index.dart';
import 'package:hive_ce/hive_ce.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle, LogicalKeyboardKey;
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:desktop_drop/desktop_drop.dart';
import '/state.dart';
import '/pages/node_editor/nodes/index.dart';

class NodeEditor extends StatefulWidget {
  const NodeEditor({super.key});

  @override
  State<NodeEditor> createState() => _State();
}

class _State extends State<NodeEditor> {
  bool loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppState provider = Inherited.of(context)!;
    // Only load from disk when the canvas for this project hasn't been loaded
    // yet. The flag lives on AppState (not this widget State), so returning to
    // the canvas after navigating away keeps the live in-memory graph instead
    // of reloading stale persisted config and dropping unsaved nodes/edges.
    if (provider.loadedCanvasProjectPath != provider.projectPath) {
      provider.loadedCanvasProjectPath = provider.projectPath;
      _reloadFromProject(provider);
    }
  }

  Future<void> _reloadFromProject(AppState provider) async {
    await provider.ready;
    if (!mounted) return;
    Box<Config> box = await provider.openProjectBox<Config>('configs');
    if (!mounted) return;

    var defaultConfig = await rootBundle.loadString('assets/defaultConfig.json');
    var configs = box.values.where((item) => item.name == "default");
    if (configs.isNotEmpty) {
      await _loadCanvasData(provider, jsonDecode(configs.first.data));
    } else {
      await _loadCanvasData(provider, jsonDecode(defaultConfig));
    }

    if (!mounted) return;
    setState(() {});
  }

  /// Shared loader: registers embedded dynamic node configs, then loads the canvas.
  Future<void> _loadCanvasData(AppState provider, Map<String, dynamic> json) async {
    final dynamicNodes = json['dynamicNodes'] as List<dynamic>?;
    if (dynamicNodes != null) {
      for (final configJson in dynamicNodes) {
        try {
          final config = NodeConfig.fromJson(configJson);
          provider.registerDynamicNodeConfig(config);
        } catch (e) {
          debugPrint('Failed to register embedded dynamic node: $e');
        }
      }
    }
    await provider.nodeController.fromJson(json, context);
  }

  Future<void> saveCanvas({bool saveAsFile = false}) async {
    AppState provider = Inherited.of(context)!;
    Box<Config> configs = await provider.openProjectBox<Config>('configs');

    final canvasJson = provider.nodeController.toJson();

    // Embed dynamic node configs used on the canvas
    final dynamicConfigs = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final node in provider.nodeController.nodes.values) {
      if (node is DynamicNode && seen.add(node.config.typeName)) {
        dynamicConfigs.add(node.config.toJson());
      }
    }
    if (dynamicConfigs.isNotEmpty) {
      canvasJson['dynamicNodes'] = dynamicConfigs;
    }

    var data = jsonEncode(canvasJson);

    if (configs.isNotEmpty) {
      await configs.putAt(0, Config(name: "default", data: data));
    } else {
      await configs.add(Config(name: "default", data: data));
    }
    await configs.flush();

    if (saveAsFile) {
      String? path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save config',
        fileName: 'sdconfig.json',
      );
      if (path != null) {
        await File(path).writeAsBytes(Uint8List.fromList(data.codeUnits));
      }
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
        await _loadCanvasData(provider, jsonDecode(data));
      } catch (err) {
        print("failed to load config ${err.toString()}");
      }
    } else {
      print("canceled");
      // User canceled the picker
    }
  }

  Future<void> loadFromUrl() async {
    AppState provider = Inherited.of(context)!;
    final urlController = TextEditingController();

    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Load config from URL'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'https://example.com/config.json',
            labelText: 'URL',
          ),
          autofocus: true,
          onSubmitted: (value) => Navigator.of(ctx).pop(value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(urlController.text), child: const Text('Load')),
        ],
      ),
    );

    if (url == null || url.trim().isEmpty) return;

    setState(() => loading = true);
    try {
      final response = await http.get(Uri.parse(url.trim()));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      await _loadCanvasData(provider, json);
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $err')),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _onImageDropped(DropDoneDetails details) async {
    final provider = Inherited.of(context)!;
    const imageExtensions = {'.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'};

    for (final file in details.files) {
      final name = file.name.toLowerCase();
      final ext = name.contains('.') ? '.${name.split('.').last}' : '';
      if (!imageExtensions.contains(ext)) continue;

      final bytes = await File(file.path).readAsBytes();
      final node = ImageNode();
      await node.loadImageBytes(bytes, fileName: file.name);
      provider.nodeController.addNode(node, details.localPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppState provider = Inherited.of(context)!;
    ThemeData theme = Theme.of(context);
    return NodeControls(
      notifier: provider.nodeController,
      child: CallbackShortcuts(
        bindings: {SingleActivator(LogicalKeyboardKey.keyS, control: true): saveCanvas},
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: DropTarget(
              onDragDone: _onImageDropped,
              child: Stack(
                children: [
                  NodeCanvas(
                    controller: provider.nodeController,
                    zoom: 0.5,
                    backgroundColor: Colors.black87,
                    lineColor: const Color.fromARGB(255, 166, 164, 164),
                  ),
                  if (loading) const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
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
                    FloatingActionButton(heroTag: "url", onPressed: loadFromUrl, child: Icon(Icons.link)),
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
