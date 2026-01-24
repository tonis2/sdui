import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:ui' as ui;
import '/components/node_editor/index.dart';

class ImageOutput {
  Uint8List data;
  Size size;
  ImageOutput({required this.data, required this.size});
}

class ImageNode extends Node {
  ImageNode({
    super.color = Colors.lightGreen,
    super.label = "Image",
    super.size = const Size(400, 400),
    super.inputs = const [],
    super.outputs = const [Output(label: "Image", color: Colors.yellow), Output(label: "Mask")],
    super.offset,
    super.uuid,
    super.key,
  });

  factory ImageNode.fromJson(Map<String, dynamic> json) {
    final data = Node.fromJson(json);
    return ImageNode(
      label: "Image",
      size: const Size(400, 400),
      color: Colors.lightGreen,
      inputs: const [],
      outputs: const [
        Output(label: "Image", color: Colors.yellow),
        Output(label: "Mask"),
      ],
      offset: data.offset,
      uuid: data.uuid,
    );
  }

  ui.Image? image;
  Uint8List? data;

  @override
  Future<ImageOutput> execute(BuildContext context) async {
    if (image == null) throw Exception("Image is empty");
    return ImageOutput(data: data!, size: Size(image!.width.toDouble(), image!.height.toDouble()));
  }

  void pickImage(BuildContext context) async {
    // Capture the controller before any async operations
    NodeEditorController? provider = NodeControls.of(context);
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.first;
      image = await decodeImageFromList(file.bytes!);
      data = file.bytes!;
      provider?.requestUpdate();
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
                        provider?.requestUpdate();
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
