import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import '/components/index.dart';
import '/models/index.dart';
import '/state.dart';
import 'package:file_saver/file_saver.dart';

class GenerateImage extends StatefulWidget {
  @override
  State<GenerateImage> createState() => _State();
}

class _State extends State<GenerateImage> {
  CanvasController painterController = CanvasController();
  ImagePrompt imagePrompt = ImagePrompt(prompt: "", negativePrompt: "");
  bool loading = false;

  Future<FilePickerResult?> pickContextImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      PlatformFile image = result.files.first;
      imagePrompt.clearImages();

      painterController.setBackground(
        BackgroundImage(width: imagePrompt.width, height: imagePrompt.height, data: image.bytes!, name: image.name),
      );

      imagePrompt.addExtraImage(image.bytes!);
    } else {
      print("canceled");
      // User canceled the picker
    }

    return result;
  }

  Future<FilePickerResult?> pickMainImage(int width, int height) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      PlatformFile image = result.files.first;
      imagePrompt.clearImages();

      painterController.setBackground(
        BackgroundImage(width: imagePrompt.width, height: imagePrompt.height, data: image.bytes!, name: image.name),
      );

      imagePrompt.addInitImage(image.bytes!);
    } else {
      print("canceled");
      // User canceled the picker
    }

    return result;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void generateImage() async {
    try {
      AppState provider = Inherited.of(context)!;
      setState(() {
        loading = true;
      });

      PromptResponse? response = await provider.api?.postImageToImage(imagePrompt);

      setState(() {
        loading = false;
      });

      if (response != null && response.images.isNotEmpty) {
        var newImage = BackgroundImage(
          width: imagePrompt.width,
          height: imagePrompt.height,
          data: response.images.first,
          name: response.info,
        );
        painterController.setBackground(newImage);
        provider.addImage(newImage);
      }
    } catch (err) {
      print(err.toString());

      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    OutlineInputBorder inputBorder = OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1));
    TextStyle? inputText = theme.textTheme.bodyMedium;
    var doubleInputFilter = FilteringTextInputFormatter.allow(RegExp(r'(^\d*[\.]?\d{0,2})'));

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        spacing: 15,
        children: [
          Container(
            width: MediaQuery.sizeOf(context).width * 0.45,
            height: MediaQuery.sizeOf(context).height,
            child: Form(
              child: Column(
                mainAxisSize: .min,
                spacing: 10,
                children: [
                  Text("Generation options", style: theme.textTheme.bodyLarge),
                  Divider(),
                  SizedBox(height: 6),
                  TextFormField(
                    initialValue: imagePrompt.prompt,
                    decoration: InputDecoration(
                      label: Text("Prompt", style: inputText),
                      border: inputBorder,
                    ),
                    minLines: 2,
                    maxLines: 10,
                    keyboardType: TextInputType.multiline,
                    onChanged: (value) {
                      imagePrompt.prompt = value;
                    },
                  ),
                  TextFormField(
                    initialValue: imagePrompt.negativePrompt,
                    decoration: InputDecoration(
                      label: Text("Negative prompt", style: inputText),
                      border: inputBorder,
                    ),
                    minLines: 2,
                    maxLines: 10,
                    keyboardType: TextInputType.multiline,
                    onChanged: (value) {
                      imagePrompt.negativePrompt = value;
                    },
                  ),
                  SizedBox(
                    width: double.maxFinite,
                    height: 350,
                    child: GridView(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 70,
                        crossAxisSpacing: 15,
                      ),
                      children: [
                        TextFormField(
                          initialValue: imagePrompt.seed.toString(),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            label: Text("Seed", style: inputText),
                            border: inputBorder,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            imagePrompt.seed = int.tryParse(value) ?? -1;
                          },
                        ),
                        TextFormField(
                          initialValue: imagePrompt.sampler,
                          decoration: InputDecoration(
                            label: Text("Sampler", style: inputText),
                            border: inputBorder,
                          ),
                          keyboardType: TextInputType.text,
                          onChanged: (value) {
                            imagePrompt.sampler = value;
                          },
                        ),
                        TextFormField(
                          initialValue: imagePrompt.steps.toString(),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            label: Text("Steps", style: inputText),
                            border: inputBorder,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            imagePrompt.steps = int.tryParse(value) ?? -1;
                          },
                        ),
                        TextFormField(
                          initialValue: imagePrompt.guidance.toString(),
                          inputFormatters: [doubleInputFilter],
                          decoration: InputDecoration(
                            label: Text("Guidance (CFG)", style: inputText),
                            border: inputBorder,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            imagePrompt.guidance = double.tryParse(value) ?? 1;
                          },
                        ),
                        TextFormField(
                          initialValue: imagePrompt.width.toString(),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            label: Text("Width", style: inputText),
                            border: inputBorder,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            imagePrompt.width = int.tryParse(value) ?? -1;
                            painterController.resize(imagePrompt.width, imagePrompt.height);
                          },
                        ),
                        TextFormField(
                          initialValue: imagePrompt.height.toString(),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            label: Text("Height", style: inputText),
                            border: inputBorder,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            imagePrompt.height = int.tryParse(value) ?? -1;
                            painterController.resize(imagePrompt.width, imagePrompt.height);
                          },
                        ),

                        TextFormField(
                          initialValue: imagePrompt.noiseStrenght.toString(),
                          inputFormatters: [doubleInputFilter],
                          decoration: InputDecoration(
                            label: Text("Denoise strength", style: inputText),
                            border: inputBorder,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            imagePrompt.noiseStrenght = double.tryParse(value) ?? 4;
                          },
                        ),
                        TextFormField(
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
                              value: imagePrompt.maskInvert,
                              onChanged: (bool? value) {
                                setState(() {
                                  imagePrompt.maskInvert = value!;
                                });
                              },
                            ),
                            Text("invert mask", style: inputText),
                          ],
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: TextFormField(
                            decoration: InputDecoration(
                              label: Text("Context image", style: inputText),
                              border: inputBorder,
                              prefixIcon: Icon(Icons.image, color: Colors.black),
                            ),
                            keyboardType: TextInputType.text,
                            readOnly: true,
                            onTap: () => pickContextImage(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    spacing: 10,
                    children: [
                      SizedBox(
                        width: 150,
                        height: 60,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: TextFormField(
                            decoration: InputDecoration(
                              label: Text("Pick main image", style: inputText),
                              border: inputBorder,
                              prefixIcon: Icon(Icons.image, color: Colors.black),
                            ),
                            keyboardType: TextInputType.text,
                            readOnly: true,
                            onTap: () => pickMainImage(imagePrompt.width, imagePrompt.height),
                          ),
                        ),
                      ),
                      TextButton(
                        child: Text('Generate image', style: theme.textTheme.bodyLarge),
                        onPressed: generateImage,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                if (loading) CircularProgressIndicator(),
                if (!loading)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(5)),
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.all(25),
                      child: CanvasPainter(controller: painterController),
                    ),
                  ),
                Row(
                  children: [
                    SizedBox(
                      width: 70,
                      height: 40,
                      child: TextFormField(
                        initialValue: painterController.strokeWidth.toString(),
                        decoration: InputDecoration(
                          label: Text("Stroke", style: inputText),
                          border: inputBorder,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          painterController.strokeWidth = double.parse(value);
                        },
                      ),
                    ),
                    TextButton(
                      child: Text('Save image', style: theme.textTheme.bodyLarge),
                      onPressed: () async {
                        try {
                          AppState provider = Inherited.of(context)!;
                          var background = painterController.backgroundLayers.first;

                          await FileSaver.instance.saveFile(
                            name: background.name ?? "default",
                            mimeType: MimeType.png,
                            bytes: background.data,
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
        ],
      ),
    );
  }
}
