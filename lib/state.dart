import 'package:hive_ce/hive_ce.dart';
import 'package:flutter/material.dart';
import '/services/api.dart';
import '/components/index.dart';
export '/services/api.dart';
import '/models/index.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';

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

Future<AppState> createState({required KoboldApi api}) async {
  Hive.registerAdapter(ImageAdapter());

  // Open settings box to track encryption status
  final settings = await Hive.openBox('settings');

  return AppState(api: api, settings: settings);
}

class AppState extends ChangeNotifier {
  AppState({required this.api, required this.settings});

  CanvasController painterController = CanvasController(paintColor: Colors.white);
  ImagePrompt imagePrompt = ImagePrompt(prompt: "", negativePrompt: "", seed: 10);
  KoboldApi api;
  Box settings;
  LazyBox<BackgroundImage>? images;
  List<QueueItem> promptQueue = [];
  int imagesOnPage = 15;

  void loadData(BuildContext context) {
    ThemeData theme = Theme.of(context);
    // Creates / loads hive memory storage.

    if (images != null) return;

    final bool isEncrypted = settings.get('imagesEncrypted', defaultValue: false);

    Hive.boxExists("images").then((value) {
      if (value == false) {
        // Box doesn't exist - ask user if they want encryption
        _showPasswordDialog(context, theme, isNewBox: true);
      } else if (isEncrypted) {
        // Box exists and is encrypted - prompt for password
        _showPasswordDialog(context, theme, isNewBox: false);
      } else {
        // Box exists and is not encrypted
        Hive.openLazyBox<BackgroundImage>('images').then((response) => images = response).catchError((err) {
          print(err);
        });
      }
    });
  }

  void _showPasswordDialog(BuildContext context, ThemeData theme, {required bool isNewBox}) {
    String? password;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isNewBox
                ? "Storage created first time, do you want to use password for storage?"
                : "Enter password to unlock storage",
            style: theme.textTheme.titleSmall,
          ),
          content: SizedBox(
            width: 600,
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 10,
              children: [
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(label: Text("Password", style: theme.textTheme.bodyMedium)),
                  onChanged: (value) => password = value,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 25,
                  children: [
                    ElevatedButton(
                      style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(theme.colorScheme.secondary)),
                      onPressed: () => Navigator.pop(context, password),
                      child: Text("Submit", style: theme.textTheme.bodyMedium),
                    ),
                    if (isNewBox)
                      ElevatedButton(
                        style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(theme.colorScheme.secondary)),
                        onPressed: () => Navigator.pop(context),
                        child: Text("Skip", style: theme.textTheme.bodyMedium),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((response) {
      if (response != null && response.toString().isNotEmpty) {
        // User provided password
        Hive.openLazyBox<BackgroundImage>(
              'images',
              encryptionCipher: HiveAesCipher(generateEncryptionKey(response.toString())),
            )
            .then((response) {
              images = response;
              if (isNewBox) {
                settings.put('imagesEncrypted', true);
              }
            })
            .catchError((err) {
              print(err);
            });
      } else if (isNewBox) {
        // New box without encryption
        Hive.openLazyBox<BackgroundImage>('images').then((response) => images = response).catchError((err) {
          print(err);
        });
      }
    });
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

          if (response.images.isNotEmpty) {
            // painterController.setBackground(newImage);
            images?.add(
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
    // if (painterController.points.isNotEmpty) {
    //   prompt.mask = await painterController.getMaskImage(Size(prompt.width.toDouble(), prompt.height.toDouble()));

    //   // Save mask for debugging
    //   // await FileSaver.instance.saveFile(
    //   //   name: "default",
    //   //   mimeType: MimeType.png,
    //   //   bytes: provider.imagePrompt.extraImages.first,
    //   // );
    // }

    var queue = QueueItem(
      prompt:
          ImagePrompt(
              prompt: prompt.prompt,
              negativePrompt: prompt.negativePrompt,
              maskInvert: prompt.maskInvert,
              mask: prompt.mask,
              width: prompt.width,
              height: prompt.height,
              guidance: prompt.guidance,
              noiseStrenght: prompt.noiseStrenght,
              sampler: prompt.sampler,
              seed: prompt.seed,
              steps: prompt.steps,
            )
            ..initImages = prompt.initImages
            ..extraImages = prompt.extraImages,
      image: prompt.extraImages.firstOrNull,
      promptRequest: api.postImageToImage(prompt),
    );

    promptQueue.add(queue);
    _processPrompt(queue);

    clearImages();

    notifyListeners();
  }
}
