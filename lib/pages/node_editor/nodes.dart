import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'dart:ui' as ui;

import '/components/node_editor/index.dart';

class ImageNode extends Node {
  ImageNode({
    super.color = Colors.lightGreen,
    super.label = "Image",
    super.size = const Size(400, 400),
    super.inputs = const [],
    super.outputs = const [Output(label: "Image picker"), Output(label: "Mask")],
    super.offset,
    super.key,
  });

  ui.Image? image;
  Uint8List? data;

  @override
  void execute(NodeEditorController controller) {
    print("error");
    super.execute(controller);
  }

  void pickImage(BuildContext context) async {
    // Capture the controller before any async operations
    NodeEditorController? provider = NodeControls.of(context);
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.first;
      image = await decodeImageFromList(file.bytes!);
      data = file.bytes!;
      provider?.requestUpdate(uuid);
    } else {
      print("canceled");
      // User canceled the picker
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    NodeEditorController? provider = NodeControls.of(context);

    return Column(
      children: [
        InkWell(
          onTap: () => pickImage(context),
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(color: Colors.grey),
            child: Stack(
              children: [
                if (image == null)
                  Positioned(left: 75, top: 120, child: Text("Click to pick image", style: theme.textTheme.bodyLarge)),
                if (image != null && data != null) ...[
                  Positioned(
                    left: 0,
                    top: 0,
                    width: 300,
                    height: 300,
                    child: Image(image: MemoryImage(data!), width: 300, height: 300, fit: .cover),
                  ),
                  Positioned(
                    right: 5,
                    top: 5,
                    child: InkWell(
                      child: Icon(Icons.delete, color: Colors.redAccent),
                      onTap: () {
                        image = null;
                        data = null;
                        provider?.requestUpdate(uuid);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class KoboldAPI extends Node {
  KoboldAPI({
    super.color = Colors.lightBlue,
    super.label = "KoboldAPI",
    super.size = const Size(300, 300),
    super.inputs = const [Input(label: "Prompt")],
    super.outputs = const [Output(label: "Image", color: Colors.white)],
    super.offset,
  });

  @override
  void execute(NodeEditorController controller) {
    print("error");
    super.execute(controller);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Column(children: [Text("Prompt config", style: theme.textTheme.bodyMedium)]);
  }
}
