import 'dart:async';
import 'dart:ui' as ui;
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
  late String _defaultSduiPath;
  late String _projectPath;
  Completer<void> _readyCompleter = Completer<void>();
  Future<void> get ready => _readyCompleter.future;

  String get projectPath => _projectPath;

  Future<Box<T>> openProjectBox<T>(String name, {HiveCipher? cipher}) {
    return Hive.openBox<T>(name, path: _projectPath, encryptionCipher: cipher);
  }

  Future<LazyBox<T>> openProjectLazyBox<T>(String name, {HiveCipher? cipher}) {
    return Hive.openLazyBox<T>(name, path: _projectPath, encryptionCipher: cipher);
  }

  String get nodesDirectory => '$_projectPath/nodes';

  AppState() {
    if (!kIsWeb) {
      final home = Platform.environment['HOME'] ?? '.';
      _defaultSduiPath = '$home/.sdui';
      final dir = Directory(_defaultSduiPath);
      if (!dir.existsSync()) dir.createSync(recursive: true);
      Hive.init(_defaultSduiPath);
      _projectPath = _defaultSduiPath;
    }

    // Register nodes and storage stuff
    Hive.registerAdapter(ImageAdapter());
    Hive.registerAdapter(FolderAdapter());
    Hive.registerAdapter(ConfigAdapter());
    Hive.registerAdapter(ImagePromptAdapter());

    _registerBuiltinNodeTypes();

    if (!kIsWeb) {
      _initProject();
    }
  }

  void _registerBuiltinNodeTypes() {
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
        typeName: 'FluxNode',
        displayName: 'Flux Runner',
        description: 'Connect to llm-runner Flux HTTP server',
        icon: Icons.bolt,
        factory: (json) => FluxNode.fromJson(json),
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
  }

  Future<void> _initProject() async {
    _loadDynamicNodes();
    folders = await openProjectBox<Folder>('folders');
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    notifyListeners();
  }

  Future<void> switchProject(String newPath) async {
    _readyCompleter = Completer<void>();
    await Hive.close();
    boxMap.clear();
    nodeController.clear();
    loadedCanvasProjectPath = null;
    _projectPath = newPath;

    final dir = Directory(newPath);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final nodesDir = Directory(nodesDirectory);
    if (!nodesDir.existsSync()) nodesDir.createSync(recursive: true);

    _loadDynamicNodes();
    folders = await openProjectBox<Folder>('folders');
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    notifyListeners();
  }

  // CanvasController painterController = CanvasController(paintColor: Colors.white);

  // I hold nodeController here, so different pages can edit node canvas
  NodeEditorController nodeController = NodeEditorController();

  // Tracks which project's canvas is currently loaded into [nodeController].
  // Lives here (not on the canvas widget State) so navigating away from and
  // back to the canvas doesn't reload from disk and clobber the live graph.
  String? loadedCanvasProjectPath;

  late Box<Folder> folders;
  List<QueueItem> promptQueue = [];
  bool queueExpanded = true;

  // Cache for opene folders
  HashMap<String, LazyBox<PromptData>> boxMap = HashMap();

  void _loadDynamicNodes() {
    final dir = Directory(nodesDirectory);
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
        final dir = Directory(nodesDirectory);
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

    final request = item.promptRequest;
    if (request == null) return;

    item.active = true;
    item.startTime = DateTime.now();

    // Common teardown for both success and failure: mark done, hand the heavy
    // response + request closure back to the GC (see [QueueItem.release]), then
    // kick off the next queued prompt. Previously the error path did none of
    // this, so a failed prompt stayed active forever — wedging the queue and
    // permanently pinning its image data.
    void finish() {
      item.active = false;
      item.endTime ??= DateTime.now();
      item.release();
      notifyListeners();

      final unprocessed = promptQueue.where(
        (queued) => queued.endTime == null && queued.promptRequest != null,
      );
      if (unprocessed.isNotEmpty) {
        _processPrompt(unprocessed.first);
      }
    }

    request()
        .then((response) {
          item.response?.complete(response);
          finish();
        })
        .catchError((err) {
          debugPrint(err.toString());
          if (item.response?.isCompleted == false) item.response?.completeError(err);
          finish();
        });
  }

  /// Replace a queue entry's full-resolution input image with a small
  /// re-encoded thumbnail. The queue only ever renders it at 60x60, so keeping
  /// the full input bytes for the entry's lifetime just wastes memory. Runs
  /// fire-and-forget; on failure the original image is left untouched.
  Future<void> _shrinkThumbnail(QueueItem item) async {
    final source = item.image;
    if (source == null) return;
    try {
      final codec = await ui.instantiateImageCodec(
        source,
        targetWidth: 96,
        allowUpscaling: false,
      );
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      codec.dispose();
      if (data == null) return;
      item.image = data.buffer.asUint8List();
      notifyListeners();
    } catch (err) {
      debugPrint('Failed to shrink queue thumbnail: $err');
    }
  }

  Future<PromptResponse> createPromptRequest(ImagePrompt prompt, Future<dynamic> Function() request) async {
    var completer = Completer<PromptResponse>();
    var queue = QueueItem(response: completer, image: prompt.extraImages.firstOrNull, promptRequest: request);

    promptQueue.add(queue);
    _shrinkThumbnail(queue);
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
    _shrinkThumbnail(queue);

    // Start immediately (concurrent)
    queue.active = true;
    queue.startTime = DateTime.now();
    notifyListeners();

    request().then((response) {
      queue.endTime = DateTime.now();
      queue.active = false;
      completer.complete(response);
      // Local [completer]/[request] still hold what the caller awaits; this
      // just stops the queue entry from pinning the response's image bytes.
      queue.release();
      notifyListeners();
    }).catchError((err) {
      queue.endTime = DateTime.now();
      queue.active = false;
      completer.completeError(err);
      queue.release();
      notifyListeners();
    });

    return completer.future;
  }
}
