import 'dart:async';
import 'package:hive_ce/hive_ce.dart';
import 'package:flutter/material.dart';
import '/models/index.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:collection';
import '/pages/node_editor/nodes/index.dart';
import 'package:easy_nodes/index.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Directory, File, Platform;

Uint8List generateEncryptionKey(String password) {
  final salt = utf8.encode('sdui_hive_encryption_salt');
  final passwordBytes = utf8.encode(password);

  // PBKDF2-like key derivation with 100,000 iterations
  var key = Uint8List.fromList([...salt, ...passwordBytes]);
  for (var i = 0; i < 100000; i++) {
    key = Uint8List.fromList(sha256.convert(key).bytes);
  }

  return key;
}

class Inherited extends InheritedNotifier<AppState> {
  const Inherited({required super.child, super.key, required super.notifier});
  static AppState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Inherited>()?.notifier;
  }

  @override
  bool updateShouldNotify(InheritedNotifier<AppState> oldWidget) => true;
}

class AppState extends ChangeNotifier {
  AppState() {
    if (!kIsWeb) {
      final home = Platform.environment['HOME'] ?? '.';
      final dir = Directory('$home/.sdui');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      Hive.init(dir.path);
    }

    // Register nodes and storage stuff
    Hive.registerAdapter(ImageAdapter());
    Hive.registerAdapter(FolderAdapter());
    Hive.registerAdapter(ConfigAdapter());
    Hive.registerAdapter(ImagePromptAdapter());

    nodeController.registerNodeType(
      NodeTypeMetadata(
        typeName: 'ImageNode',
        displayName: 'Image',
        description: 'Load and display images',
        icon: Icons.image,
        factory: (json) => ImageNode.fromJson(json),
      ),
    );

    nodeController.registerNodeType(
      NodeTypeMetadata(
        typeName: 'PromptNode',
        displayName: 'Prompt Config',
        description: 'Configure AI prompts',
        icon: Icons.edit_note,
        factory: (json) => PromptNode.fromJson(json),
      ),
    );

    nodeController.registerNodeType(
      NodeTypeMetadata(
        typeName: 'KoboldNode',
        displayName: 'Kobold API',
        description: 'Connect to Kobold AI API',
        icon: Icons.smart_toy,
        factory: (json) => KoboldNode.fromJson(json),
      ),
    );

    nodeController.registerNodeType(
      NodeTypeMetadata(
        typeName: 'HunyuanNode',
        displayName: 'Hunyuan 3D',
        description: 'Generate 3D models from images',
        icon: Icons.view_in_ar,
        factory: (json) => HunyuanNode.fromJson(json),
      ),
    );

    nodeController.registerNodeType(
      NodeTypeMetadata(
        typeName: 'FolderNode',
        displayName: 'Folder',
        description: 'Organize files in folders',
        icon: Icons.folder,
        factory: (json) => FolderNode.fromJson(json),
      ),
    );
    if (!kIsWeb) _loadDynamicNodes();

    Hive.openBox<Folder>('folders').then((box) {
      folders = box;
    });
  }

  // CanvasController painterController = CanvasController(paintColor: Colors.white);

  // I hold nodeController here, so different pages can edit node canvas
  NodeEditorController nodeController = NodeEditorController();

  late Box<Folder> folders;
  List<QueueItem> promptQueue = [];
  bool queueExpanded = true;

  // Cache for opene folders
  HashMap<String, LazyBox<PromptData>> boxMap = HashMap();

  void _loadDynamicNodes() {
    final home = Platform.environment['HOME'] ?? '.';
    final dir = Directory('$home/.sdui/nodes');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      return;
    }

    for (final file in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
      try {
        final config = NodeConfig.fromJson(jsonDecode(file.readAsStringSync()));
        nodeController.registerNodeType(
          NodeTypeMetadata(
            typeName: config.typeName,
            displayName: config.displayName,
            description: config.description ?? '',
            icon: iconMap[config.icon] ?? Icons.extension,
            factory: (json) => DynamicNode.fromJson(json, config),
          ),
        );
      } catch (e) {
        debugPrint('Failed to load dynamic node from ${file.path}: $e');
      }
    }
  }

  /// Register a dynamic node config on-the-fly and save it to ~/.sdui/nodes/.
  /// Skips if a node with the same typeName is already registered.
  void registerDynamicNodeConfig(NodeConfig config) {
    if (nodeController.getNodeMetadata(config.typeName) != null) return;

    nodeController.registerNodeType(
      NodeTypeMetadata(
        typeName: config.typeName,
        displayName: config.displayName,
        description: config.description ?? '',
        icon: iconMap[config.icon] ?? Icons.extension,
        factory: (json) => DynamicNode.fromJson(json, config),
      ),
    );

    // Persist to disk so it's available on next startup
    if (!kIsWeb) {
      try {
        final home = Platform.environment['HOME'] ?? '.';
        final dir = Directory('$home/.sdui/nodes');
        if (!dir.existsSync()) dir.createSync(recursive: true);
        File('${dir.path}/${config.typeName}.json').writeAsStringSync(jsonEncode(config.toJson()));
      } catch (e) {
        debugPrint('Failed to save dynamic node config ${config.typeName}: $e');
      }
    }
  }

  void requestUpdate() {
    notifyListeners();
  }

  void _processPrompt(QueueItem item) {
    // Dont send new prompt, if one is already in progress
    if (promptQueue.where((item) => item.active == true).isNotEmpty) return;

    item.active = true;
    item.startTime = DateTime.now();

    item
        .promptRequest()
        .then((response) {
          QueueItem lastPrompt = promptQueue.firstWhere((item) => item.active == true);

          // Promise finished
          lastPrompt.endTime = DateTime.now();
          lastPrompt.active = false;
          lastPrompt.response.complete(response);

          notifyListeners();

          var unprocessedPrompts = promptQueue.where((item) => item.endTime == null);
          if (unprocessedPrompts.isNotEmpty) {
            _processPrompt(unprocessedPrompts.first);
          }
        })
        .catchError((err) {
          debugPrint(err.toString());
        });
  }

  Future<PromptResponse> createPromptRequest(ImagePrompt prompt, Future<dynamic> Function() request) async {
    var completer = Completer<PromptResponse>();
    var queue = QueueItem(response: completer, image: prompt.extraImages.firstOrNull, promptRequest: request);

    promptQueue.add(queue);
    _processPrompt(queue);
    notifyListeners();

    return await completer.future;
  }

  /// Enqueue a request without requiring an ImagePrompt.
  /// Runs concurrently (does not wait for other queue items to finish).
  Future<PromptResponse> enqueueRequest(Future<PromptResponse> Function() request, {Uint8List? image}) async {
    var completer = Completer<PromptResponse>();
    var queue = QueueItem(response: completer, image: image, promptRequest: request);

    promptQueue.add(queue);

    // Start immediately (concurrent)
    queue.active = true;
    queue.startTime = DateTime.now();
    notifyListeners();

    request().then((response) {
      queue.endTime = DateTime.now();
      queue.active = false;
      completer.complete(response);
      notifyListeners();
    }).catchError((err) {
      queue.endTime = DateTime.now();
      queue.active = false;
      completer.completeError(err);
      notifyListeners();
    });

    return completer.future;
  }
}
