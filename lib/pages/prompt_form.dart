import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import '/components/index.dart';
import '/models/index.dart';
import '/state.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:math';

class GenerateImage extends StatefulWidget {
  const GenerateImage({super.key});

  @override
  State<GenerateImage> createState() => _State();
}

class ISize {
  final int width;
  final int height;

  ISize({required this.width, required this.height});
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
      // AppState provider = Inherited.of(context)!;
      // widthController.text = provider.imagePrompt.width.toString();
      // heightController.text = provider.imagePrompt.height.toString();
      // promptController.text = provider.imagePrompt.prompt.toString();

      setState(() {});
    });

    super.initState();
  }

  ISize calculateResize(ISize size) {
    int width = max(min(size.width.toInt(), 1024), 24);
    int height = max(min(size.height.toInt(), 1024), 24);

    if (size.width >= size.height) {
      double aspect = size.height / size.width;
      height = min((width * aspect).toInt(), 1024);
    }
    if (size.width <= size.height) {
      double aspect = size.width / size.height;
      width = min((height * aspect).toInt(), 1024);
    }

    return ISize(width: width, height: height);
  }

  void resizeImage(ISize size) {
    AppState provider = Inherited.of(context)!;
    size = calculateResize(size);
    provider.imagePrompt.width = size.width;
    provider.imagePrompt.height = size.height;
    widthController.text = size.width.toString();
    heightController.text = size.height.toString();
    setState(() {});
  }

  Future<FilePickerResult?> pickImage({bool isExtra = true}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    AppState provider = Inherited.of(context)!;
    if (result != null) {
      PlatformFile image = result.files.first;
      var decodedImage = await decodeImageFromList(image.bytes!);

      ISize newSize = calculateResize(ISize(width: decodedImage.width, height: decodedImage.height));

      provider.imagePrompt.width = newSize.width;
      provider.imagePrompt.height = newSize.height;

      provider.painterController.setBackground(
        BackgroundImage(width: newSize.width, height: newSize.height, data: image.bytes!, name: image.name),
      );

      widthController.text = newSize.width.toString();
      heightController.text = newSize.height.toString();

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
              SizedBox(
                width: size.width * 0.45,
                height: 580,
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
                                    int width = int.tryParse(value) ?? -1;
                                    resizeImage(ISize(width: width, height: provider.imagePrompt.height));
                                  },
                                ),
                                Slider(
                                  min: 64,
                                  value: double.tryParse(widthController.text) ?? provider.imagePrompt.width.toDouble(),
                                  max: 1024,
                                  divisions: 15,
                                  onChanged: (width) {
                                    resizeImage(ISize(width: width.toInt(), height: provider.imagePrompt.height));
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
                                    int height = int.tryParse(value) ?? -1;
                                    resizeImage(ISize(width: provider.imagePrompt.width, height: height));
                                  },
                                ),
                                Slider(
                                  min: 64,
                                  value:
                                      double.tryParse(heightController.text) ?? provider.imagePrompt.height.toDouble(),
                                  max: 1024,
                                  divisions: 15,
                                  onChanged: (double height) {
                                    resizeImage(ISize(width: provider.imagePrompt.width, height: height.toInt()));
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
                            flex: 1,
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
                          Flexible(
                            flex: 1,
                            child: TextFormField(
                              initialValue: provider.imagePrompt.clipSkip.toString(),
                              decoration: InputDecoration(
                                label: Text("Clip skip", style: inputText),
                                border: inputBorder,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                provider.imagePrompt.clipSkip = int.tryParse(value) ?? 0;
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

                          Flexible(
                            child: TextButton(
                              onPressed: () async {
                                provider.clearImages();
                                setState(() {});
                              },
                              child: Text("Reset canvas"),
                            ),
                          ),
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
