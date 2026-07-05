import 'dart:typed_data';
import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sdui/models/index.dart';
import 'dart:ui' as ui;
import 'package:easy_nodes/index.dart';
import 'package:image/image.dart' as img;

class ImageNode extends Node {
  @override
  String get typeName => 'ImageNode';

  ImageNode({
    super.color = Colors.lightGreen,
    super.label = "Image",
    super.size = const Size(400, 400),
    super.inputs = const [],
    super.outputs = const [Output(label: "Image", color: Colors.yellow), Output(label: "Mask")],
    super.offset,
    super.uuid,
    super.key,
    this.data,
    this.image,
    this.order = 0,
  });

  factory ImageNode.fromJson(Map<String, dynamic> json) {
    final data = Node.fromJson(json);
    final encoded = json["data"] as String?;
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
      // Restore the persisted pixel bytes. The decoded ui.Image is rebuilt
      // asynchronously in [init]; keeping the bytes here means a canvas
      // reload (e.g. navigating away and back) no longer clears the image.
      data: encoded != null ? base64.decode(encoded) : null,
      order: (json["order"] as num?)?.toInt() ?? 0,
    );
  }

  ui.Image? image;
  Uint8List? data;

  /// Explicit ordering slot for this image when several images feed the same
  /// input port. The prompt node sorts incoming images by this value ascending,
  /// so a node with order 1 lands before order 2 in the init_images array.
  int order;

  /// Rebuild the decoded [image] from the restored [data] after deserialization.
  @override
  Future<void> init(BuildContext context) async {
    if (data != null && image == null) {
      image = await decodeImageFromList(data!);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    // Persist the pixel bytes alongside the node so the image survives a
    // save/load or a canvas reload. Without this the node reloads empty and
    // any prompt using it as an init image produces a black result.
    if (data != null) json["data"] = base64.encode(data!);
    json["order"] = order;
    return json;
  }

  @override
  Future<PromptResponse> run(BuildContext context, ExecutionContext cache) async {
    if (data == null) throw Exception("Image is empty");
    return PromptResponse(images: [data!]);
  }

  /// Convert non-PNG/JPG formats (e.g. webp) to PNG bytes.
  static Uint8List _ensurePngOrJpg(Uint8List bytes, String? fileName) {
    final ext = (fileName ?? '').split('.').last.toLowerCase();
    if (ext == 'png' || ext == 'jpg' || ext == 'jpeg') return bytes;
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    return Uint8List.fromList(img.encodePng(decoded));
  }

  Future<void> loadImageBytes(Uint8List bytes, {String? fileName, NodeEditorController? provider}) async {
    data = _ensurePngOrJpg(bytes, fileName);
    image = await decodeImageFromList(data!);
    provider?.requestUpdate();
  }

  void pickImage(BuildContext context) async {
    // Capture the controller before any async operations
    NodeEditorController? provider = NodeControls.of(context);
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.first;
      final bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (bytes == null) return;
      await loadImageBytes(bytes, fileName: file.name, provider: provider);
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
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Tooltip(
                message: "Order in the images array (lower comes first)",
                child: Text("Order", style: theme.textTheme.bodyLarge),
              ),
              IconButton(
                tooltip: "Move earlier",
                icon: Icon(Icons.remove_circle, color: theme.colorScheme.onSurface),
                onPressed: () {
                  if (order > 0) order--;
                  provider?.requestUpdate();
                },
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 32),
                alignment: Alignment.center,
                child: Text("$order", style: theme.textTheme.titleMedium),
              ),
              IconButton(
                tooltip: "Move later",
                icon: Icon(Icons.add_circle, color: theme.colorScheme.onSurface),
                onPressed: () {
                  order++;
                  provider?.requestUpdate();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
