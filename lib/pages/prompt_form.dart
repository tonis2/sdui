import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import '/components/index.dart';
import '/models/index.dart';
import '/state.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:math';

class GenerateImage extends StatefulWidget {
  @override
  State<GenerateImage> createState() => _State();
}

class _State extends State<GenerateImage> {
  bool loading = false;

  TextEditingController widthController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  TextEditingController promptController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    widthController.dispose();
    heightController.dispose();
    promptController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      AppState provider = Inherited.of(context)!;
      widthController.text = provider.imagePrompt.width.toString();
      heightController.text = provider.imagePrompt.height.toString();
      promptController.text = provider.imagePrompt.prompt.toString();

      setState(() {});
    });

    super.initState();
  }

  Future<FilePickerResult?> pickImage({bool isExtra = true}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    AppState provider = Inherited.of(context)!;
    if (result != null) {
      PlatformFile image = result.files.first;
      // clearImages();
      var decodedImage = await decodeImageFromList(image.bytes!);

      if (decodedImage.width >= decodedImage.height) {
        double aspect = decodedImage.height / decodedImage.width;
        int width = min(decodedImage.width, 1024);
        int height = min(decodedImage.height, 1024);
        height = (width * aspect).toInt();
        heightController.text = height.toString();
        widthController.text = width.toString();
      }

      if (decodedImage.width <= decodedImage.height) {
        double aspect = decodedImage.width / decodedImage.height;
        int width = min(decodedImage.width, 1024);
        int height = min(decodedImage.height, 1024);
        width = (height * aspect).toInt();
        heightController.text = height.toString();
        widthController.text = width.toString();
      }

      provider.imagePrompt.width = int.parse(widthController.text);
      provider.imagePrompt.height = int.parse(heightController.text);

      provider.painterController.setBackground(
        BackgroundImage(
          width: int.parse(widthController.text),
          height: int.parse(heightController.text),
          data: image.bytes!,
          name: image.name,
        ),
      );

      if (isExtra) {
        provider.imagePrompt.addExtraImage(image.bytes!);
      } else {
        provider.imagePrompt.addInitImage(image.bytes!);
      }
      setState(() {});
    } else {
      print("canceled");
      // User canceled the picker
    }

    return result;
  }

  void generateImage() async {
    AppState provider = Inherited.of(context)!;
    if (_formKey.currentState!.validate()) {
      provider.createPromptRequest(provider.imagePrompt);
    }

    provider.clearImages();
  }

  Widget queueView() {
    AppState provider = Inherited.of(context)!;
    ThemeData theme = Theme.of(context);
    return Align(
      alignment: .center,
      child: SizedBox(
        width: 500,
        height: 110,
        child: SingleChildScrollView(
          scrollDirection: .horizontal,
          child: Row(
            mainAxisSize: .min,
            mainAxisAlignment: .start,
            crossAxisAlignment: .start,
            children: provider.promptQueue.map((item) {
              MemoryImage? image;

              if (item.image != null) {
                image = MemoryImage(item.image!);
              }

              return SizedBox(
                width: 350,
                child: Row(
                  mainAxisSize: .min,
                  mainAxisAlignment: .start,
                  crossAxisAlignment: .start,
                  spacing: 10,
                  children: [
                    if (image != null) Image(image: ResizeImage(image, width: 60, height: 60)),
                    Column(
                      mainAxisSize: .min,
                      spacing: 5,
                      children: [
                        if (item.startTime != null)
                          Text(
                            "Start time: ${item.startTime.toString().split(" ")[1]}",
                            style: theme.textTheme.bodySmall,
                          ),
                        if (item.endTime != null)
                          Text("End time: ${item.endTime.toString().split(" ")[1]}", style: theme.textTheme.bodySmall),
                        if (item.endTime != null && item.startTime != null)
                          Text(
                            "Time spent: ${item.endTime!.difference(item.startTime!).toString()}",
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        provider.promptQueue.retainWhere((item) => item.endTime == null);
                        setState(() {});
                      },
                      child: Icon(Icons.delete_forever, color: theme.colorScheme.secondary),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  FilteringTextInputFormatter doubleInputFilter = FilteringTextInputFormatter.allow(RegExp(r'(^\d*[\.]?\d{0,2})'));
  OutlineInputBorder inputBorder = OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1));

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    TextStyle? inputText = theme.textTheme.bodyMedium;
    Size size = MediaQuery.sizeOf(context);
    AppState provider = Inherited.of(context)!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      width: size.width,
      height: size.height,
      child: SingleChildScrollView(
        child: SizedBox(
          height: 950 + provider.imagePrompt.height.toDouble(),
          child: Column(
            spacing: 10,
            children: [
              if (provider.promptQueue.isNotEmpty) queueView(),
              Container(
                width: size.width * 0.45,
                height: 700,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: .min,
                    spacing: 10,
                    children: [
                      Text("Generation options", style: theme.textTheme.bodyLarge),
                      Divider(),
                      SizedBox(height: 6),
                      TextFormField(
                        controller: promptController,
                        decoration: InputDecoration(
                          label: Text("Prompt", style: inputText),
                          border: inputBorder,
                        ),
                        minLines: 2,
                        maxLines: 10,
                        keyboardType: TextInputType.multiline,
                        onChanged: (value) {
                          provider.imagePrompt.prompt = value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a prompt';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        initialValue: provider.imagePrompt.negativePrompt,
                        decoration: InputDecoration(
                          label: Text("Negative prompt", style: inputText),
                          border: inputBorder,
                        ),
                        minLines: 2,
                        maxLines: 10,
                        keyboardType: TextInputType.multiline,
                        onChanged: (value) {
                          provider.imagePrompt.negativePrompt = value;
                        },
                      ),
                      Flex(
                        direction: Axis.horizontal,
                        spacing: 10,
                        children: [
                          Flexible(
                            flex: 2,
                            child: TextFormField(
                              initialValue: provider.imagePrompt.seed.toString(),
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                label: Text("Seed", style: inputText),
                                border: inputBorder,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                provider.imagePrompt.seed = int.tryParse(value) ?? -1;
                              },
                            ),
                          ),
                          Flexible(
                            flex: 2,
                            child: TextFormField(
                              initialValue: provider.imagePrompt.sampler,
                              decoration: InputDecoration(
                                label: Text("Sampler", style: inputText),
                                border: inputBorder,
                              ),
                              keyboardType: TextInputType.text,
                              onChanged: (value) {
                                provider.imagePrompt.sampler = value;
                              },
                            ),
                          ),
                          Flexible(
                            flex: 2,
                            child: TextFormField(
                              initialValue: provider.imagePrompt.steps.toString(),
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                label: Text("Steps", style: inputText),
                                border: inputBorder,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                provider.imagePrompt.steps = int.tryParse(value) ?? -1;
                              },
                            ),
                          ),
                          Flexible(
                            flex: 2,
                            child: TextFormField(
                              initialValue: provider.imagePrompt.guidance.toString(),
                              inputFormatters: [doubleInputFilter],
                              decoration: InputDecoration(
                                label: Text("Guidance (CFG)", style: inputText),
                                border: inputBorder,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                provider.imagePrompt.guidance = double.tryParse(value) ?? 1;
                              },
                            ),
                          ),
                          Flexible(
                            flex: 2,
                            child: TextFormField(
                              initialValue: provider.imagePrompt.noiseStrenght.toString(),
                              inputFormatters: [doubleInputFilter],
                              decoration: InputDecoration(
                                label: Text("Denoise strength", style: inputText),
                                border: inputBorder,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                provider.imagePrompt.noiseStrenght = double.tryParse(value) ?? 4;
                              },
                            ),
                          ),
                          Flexible(
                            flex: 2,
                            child: TextFormField(
                              initialValue: "default",
                              decoration: InputDecoration(
                                label: Text("Scheduler", style: inputText),
                                border: inputBorder,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                // imagePrompt.noiseStrenght = double.tryParse(value) ?? 4;
                              },
                            ),
                          ),
                        ],
                      ),
                      Flex(
                        direction: .horizontal,
                        spacing: 10,
                        mainAxisAlignment: .start,
                        crossAxisAlignment: .start,
                        children: [
                          Flexible(
                            flex: 1,
                            fit: .loose,
                            child: Column(
                              mainAxisSize: .min,
                              children: [
                                TextFormField(
                                  controller: widthController,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: InputDecoration(
                                    label: Text("Width", style: inputText),
                                    border: inputBorder,
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    provider.imagePrompt.width = int.tryParse(value) ?? -1;
                                    provider.painterController.resize(
                                      provider.imagePrompt.width,
                                      provider.imagePrompt.height,
                                    );
                                  },
                                ),
                                Slider(
                                  min: 64,
                                  value: double.parse(widthController.text),
                                  max: 1024,
                                  divisions: 15,
                                  onChanged: (double value) {
                                    provider.imagePrompt.width = value.toInt();
                                    widthController.text = value.toString();
                                    provider.painterController.resize(
                                      provider.imagePrompt.width,
                                      provider.imagePrompt.height,
                                    );
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            flex: 1,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: heightController,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: InputDecoration(
                                    label: Text("Height", style: inputText),
                                    border: inputBorder,
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    provider.imagePrompt.height = int.tryParse(value) ?? -1;
                                    provider.painterController.resize(
                                      provider.imagePrompt.width,
                                      provider.imagePrompt.height,
                                    );
                                  },
                                ),
                                Slider(
                                  min: 64,
                                  value: double.parse(heightController.text),
                                  max: 1024,
                                  divisions: 15,
                                  onChanged: (double value) {
                                    provider.imagePrompt.height = value.toInt();
                                    provider.painterController.resize(
                                      provider.imagePrompt.width,
                                      provider.imagePrompt.height,
                                    );
                                    heightController.text = value.toString();
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Flex(
                        direction: Axis.horizontal,
                        spacing: 10,
                        children: [
                          Flexible(
                            flex: 2,
                            child: TextFormField(
                              initialValue: provider.imagePrompt.frames.toString(),
                              decoration: InputDecoration(
                                label: Text("Frames", style: inputText),
                                border: inputBorder,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                provider.imagePrompt.frames = int.tryParse(value) ?? 0;
                              },
                            ),
                          ),
                        ],
                      ),
                      Flex(
                        direction: .horizontal,
                        spacing: 10,
                        mainAxisAlignment: .start,
                        crossAxisAlignment: .start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                checkColor: Colors.white,
                                fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                  if (states.contains(WidgetState.disabled)) {
                                    return Colors.amber.withValues(alpha: 0.5);
                                  }
                                  return Colors.amber;
                                }),
                                value: provider.imagePrompt.maskInvert,
                                onChanged: (bool? value) {
                                  setState(() {
                                    provider.imagePrompt.maskInvert = value!;
                                  });
                                },
                              ),
                              Text("invert mask", style: inputText),
                            ],
                          ),
                          Flexible(
                            child: TextButton(onPressed: pickImage, child: Text("Pick context image")),
                          ),
                          Flexible(
                            child: TextButton(
                              onPressed: () => pickImage(isExtra: false),
                              child: Text("Pick main image"),
                            ),
                          ),
                          // Flexible(
                          //   child: TextButton(
                          //     onPressed: () async {
                          //       FilePickerResult? result = await FilePicker.platform.pickFiles();
                          //       if (result != null) {
                          //         PlatformFile image = result.files.first;
                          //         provider.imagePrompt.mask = image.bytes;
                          //       }
                          //     },
                          //     child: Text("Pick mask"),
                          //   ),
                          // ),
                          // Flexible(
                          //   child: TextButton(
                          //     onPressed: () async {
                          //       clearImages();
                          //       setState(() {});
                          //     },
                          //     child: Text("Reset canvas"),
                          //   ),
                          // ),
                        ],
                      ),
                      TextButton(
                        onPressed: generateImage,
                        child: Text('Generate image', style: theme.textTheme.bodyLarge),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: provider.imagePrompt.width.toDouble(),
                height: provider.imagePrompt.height.toDouble(),
                decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(5)),
                margin: EdgeInsets.only(top: 10, bottom: 15),
                child: CanvasPainter(
                  controller: provider.painterController,
                  size: Size(provider.imagePrompt.width.toDouble(), provider.imagePrompt.height.toDouble()),
                ),
              ),
              Row(
                crossAxisAlignment: .center,
                mainAxisAlignment: .center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 40,
                    child: TextFormField(
                      initialValue: provider.painterController.strokeWidth.toString(),
                      decoration: InputDecoration(
                        label: Text("Stroke", style: inputText),
                        border: inputBorder,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        provider.painterController.strokeWidth = double.parse(value);
                      },
                    ),
                  ),
                  TextButton(
                    child: Text('Save image', style: theme.textTheme.bodyLarge),
                    onPressed: () async {
                      try {
                        var background = provider.painterController.backgroundLayer;

                        await FileSaver.instance.saveFile(
                          name: background?.name ?? "default",
                          mimeType: MimeType.png,
                          bytes: background?.data,
                        );
                      } catch (err) {
                        print(err.toString());

                        setState(() {
                          loading = false;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
