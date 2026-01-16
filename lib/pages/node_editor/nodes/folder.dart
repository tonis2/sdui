import 'package:flutter/material.dart';
import '/components/node_editor/index.dart';

class FolderNode extends Node {
  FolderNode({
    super.color = Colors.lightGreen,
    super.label = "Folder",
    super.size = const Size(400, 400),
    super.inputs = const [Input(label: "Result")],
    super.outputs = const [],
    super.offset,
    super.uuid,
    super.key,
  });

  factory FolderNode.fromJson(Map<String, dynamic> json) {
    final data = Node.fromJson(json);

    return FolderNode(
      label: "Folder",
      offset: data.offset,
      size: const Size(400, 400),
      color: Colors.lightGreen,
      inputs: const [Input(label: "Result")],
      outputs: const [],
      uuid: data.uuid,
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
