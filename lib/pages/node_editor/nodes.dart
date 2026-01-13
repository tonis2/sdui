import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:math';

import '/components/node_editor/index.dart';

class ImageNode extends Node {
  ImageNode({
    super.color = Colors.lightGreen,
    super.label = "Image",
    super.size = const Size(400, 400),
    super.inputs = const [],
    super.outputs = const [Output(label: "Image"), Output(label: "Mask")],
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
    return Column(children: [Text("Image picker", style: theme.textTheme.bodyMedium)]);
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
