import 'package:hive_ce/hive_ce.dart';
import 'package:flutter/material.dart';
import '/services/api.dart';
import '/components/index.dart';
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

  CanvasController painterController = CanvasController(paintColor: Colors.white);
  ImagePrompt imagePrompt = ImagePrompt(prompt: "", negativePrompt: "", seed: 10);
  KoboldApi api;
  Box<BackgroundImage> images;
  List<QueueItem> promptQueue = [];
  int imagesOnPage = 15;

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

          if (response.images.isNotEmpty) {
            // painterController.setBackground(newImage);
            images.add(
              BackgroundImage(
                width: lastPrompt.prompt.width,
                height: lastPrompt.prompt.height,
                prompt: lastPrompt.prompt.prompt,
                data: response.images.first,
                name: response.info,
              ),
            );
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

  void clearImages() {
    painterController.clear();
    imagePrompt.clearImages();
    notifyListeners();
  }

  void createPromptRequest(ImagePrompt prompt) async {
    var queue = QueueItem(
      prompt: ImagePrompt(
        prompt: prompt.prompt,
        negativePrompt: prompt.negativePrompt,
        maskInvert: prompt.maskInvert,
        width: prompt.width,
        height: prompt.height,
        guidance: prompt.guidance,
        noiseStrenght: prompt.noiseStrenght,
        sampler: prompt.sampler,
        seed: prompt.seed,
        steps: prompt.steps,
      ),
      image: prompt.extraImages.firstOrNull,
      promptRequest: api.postImageToImage(prompt),
    );

    if (painterController.points.isNotEmpty) {
      prompt.mask = await painterController.getMaskImage(Size(prompt.width.toDouble(), prompt.height.toDouble()));

      // Save mask for debugging
      // await FileSaver.instance.saveFile(name: "default", mimeType: MimeType.png, bytes: provider.imagePrompt.mask);
      // await FileSaver.instance.saveFile(
      //   name: "default",
      //   mimeType: MimeType.png,
      //   bytes: provider.imagePrompt.extraImages.first,
      // );
    }

    promptQueue.add(queue);
    _processPrompt(queue);
    notifyListeners();
  }
}
