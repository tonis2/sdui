import 'package:hive_ce/hive_ce.dart';
import 'package:flutter/material.dart';
import '/services/api.dart';

export '/services/api.dart';
import '/models/index.dart';

class Inherited extends InheritedNotifier<AppState> {
  const Inherited({required super.child, super.key, required super.notifier});
  static AppState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Inherited>()!.notifier;
  }

  @override
  bool updateShouldNotify(InheritedNotifier<AppState> oldState) => true;
}

Future<AppState> createState({required KoboldApi api}) async {
  Hive.registerAdapter(ImageAdapter());
  var images = await Hive.openBox<BackgroundImage>('images');
  return AppState(api: api, images: images);
}

class AppState extends ChangeNotifier {
  AppState({required this.api, required this.images});

  ImagePrompt imagePrompt = ImagePrompt(prompt: "", negativePrompt: "");
  KoboldApi api;
  Box<BackgroundImage> images;
  List<QueueItem> promptQueue = [];

  void _processPrompt(QueueItem item) {
    bool hasPromptInProccess = promptQueue.where((item) => item.active == true).isNotEmpty;

    if (hasPromptInProccess) return;

    item.active = true;
    item.startTime = DateTime.now();

    item.promptRequest
        .then((response) {
          // Promise finished
          item.endTime = DateTime.now();
          item.active = false;

          if (response.images.isNotEmpty) {
            var newImage = BackgroundImage(
              width: item.prompt.width,
              height: item.prompt.height,
              data: response.images.first,
              name: response.info,
            );

            // painterController.setBackground(newImage);
            images.add(newImage);
            notifyListeners();
          } else {
            debugPrint("Image processing failed");
          }

          var unprocessedPrompts = promptQueue.where((item) => item.endTime == null);
          if (unprocessedPrompts.isNotEmpty) {
            _processPrompt(unprocessedPrompts.first);
          }
        })
        .catchError((err) {
          debugPrint(err.toString());
        });
  }

  void createPromptRequest(QueueItem item) {
    promptQueue.add(item);
    item.image = item.prompt.extraImages.firstOrNull;
    _processPrompt(item);
    notifyListeners();
  }
}
