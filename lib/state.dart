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
        typeName: 'FolderNode',
        displayName: 'Folder',
        description: 'Organize files in folders',
        icon: Icons.folder,
        factory: (json) => FolderNode.fromJson(json),
      ),
    );
    Hive.openBox<Folder>('folders').then((box) {
      folders = box;
    });
  }

  // CanvasController painterController = CanvasController(paintColor: Colors.white);

  // I hold nodeController here, so different pages can edit node canvas
  NodeEditorController nodeController = NodeEditorController();

  late Box<Folder> folders;
  List<QueueItem> promptQueue = [];

  // Cache for opene folders
  HashMap<String, LazyBox<PromptData>> boxMap = HashMap();

  void requestUpdate() {
    notifyListeners();
  }

  void _processPrompt(QueueItem item) {
    // Dont send new prompt, if one is already in progress
    if (promptQueue.where((item) => item.active == true).isNotEmpty) return;

    item.active = true;
    item.startTime = DateTime.now();

    item.promptRequest
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

  Future<PromptResponse> createPromptRequest(ImagePrompt prompt, Future<PromptResponse> request) async {
    // if (painterController.points.isNotEmpty) {
    //   prompt.mask = await painterController.getMaskImage(Size(prompt.width.toDouble(), prompt.height.toDouble()));

    //   // Save mask for debugging
    //   // await FileSaver.instance.saveFile(
    //   //   name: "default",
    //   //   mimeType: MimeType.png,
    //   //   bytes: provider.imagePrompt.extraImages.first,
    //   // );
    // }

    var completer = Completer<PromptResponse>();
    var queue = QueueItem(response: completer, image: prompt.extraImages.firstOrNull, promptRequest: request);

    promptQueue.add(queue);
    _processPrompt(queue);
    notifyListeners();

    return await completer.future;
  }
}
