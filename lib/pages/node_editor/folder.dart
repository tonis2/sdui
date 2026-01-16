import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:ui' as ui;
import '/components/node_editor/index.dart';

class Folder extends Node {
  Folder({
    super.color = Colors.lightGreen,
    super.label = "Folder",
    super.size = const Size(400, 400),
    super.inputs = const [Input(label: "Result")],
    super.outputs = const [],
    super.offset,
    super.uuid,
    super.key,
  });

  factory Folder.fromJson(Map<String, dynamic> json) {
    final data = Node.fromJson(json);

    return Folder(
      label: data.label,
      offset: data.offset,
      size: data.size,
      color: data.color,
      inputs: data.inputs,
      outputs: data.outputs,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    return json;
  }

  @override
  Future<void> execute(BuildContext context) async {}

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    NodeEditorController? provider = NodeControls.of(context);

    return Column(
      children: [
        InkWell(
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(color: Colors.grey),
            child: Stack(children: []),
          ),
        ),
      ],
    );
  }
}
