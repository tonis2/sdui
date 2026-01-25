import 'package:flutter/material.dart';
import 'package:easy_nodes/index.dart';
import '/models/index.dart';
import '/state.dart';
import '/pages/folder.dart';

List<FormInput> _defaultNodes = [
  FormInput(label: "Folders", type: FormInputType.dropdown, width: 300, height: 80, validator: defaultValidator),
];

class FolderNode extends FormNode {
  @override
  String get typeName => 'FolderNode';

  FolderNode({
    super.color = Colors.lightGreen,
    super.label = "Folder",
    super.size = const Size(400, 200),
    super.inputs = const [Input(label: "Result", color: Colors.yellow)],
    super.outputs = const [],
    super.offset,
    super.uuid,
    super.key,
    List<FormInput>? customFormInputs,
  }) : super(formInputs: customFormInputs ?? []);

  factory FolderNode.fromJson(Map<String, dynamic> json) {
    final data = Node.fromJson(json);
    final formInputs =
        (json["formInputs"] as List<dynamic>?)?.map((i) => FormInput.fromJson(i)).toList() ?? _defaultNodes;
    return FolderNode(
      label: "Folder",
      size: const Size(400, 200),
      color: Colors.lightGreen,
      inputs: const [Input(label: "Image", color: Colors.yellow)],
      outputs: const [],
      uuid: data.uuid,
      offset: data.offset,
      customFormInputs: formInputs,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    formInputs[0].options = [];
    return super.toJson();
  }

  Future<void> _recreateFolderList(BuildContext context) async {
    AppState provider = Inherited.of(context)!;

    if (formInputs.isNotEmpty) {
      if (formInputs[0].defaultValue != null) unlockFolder(context, formInputs[0].defaultValue!);
    }

    formInputs[0]
      ..callback = (value) {
        unlockFolder(context, value);
      }
      ..options = provider.folders.values.map((value) => value.name).toList()
      ..suffix = (context) {
        return Tooltip(
          message: "Add new folder",
          child: InkWell(
            onTap: () => createFolder(context),
            child: Icon(Icons.add, color: Colors.black, size: 35),
          ),
        );
      };
  }

  @override
  Future<void> init(BuildContext context) async {
    await _recreateFolderList(context);
    return super.init(context);
  }

  void createFolder(BuildContext context) {
    NodeEditorController? controller = NodeControls.of(context);
    AppState provider = Inherited.of(context)!;

    final nameController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog<(String, String)?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create new folder"),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Folder name", border: OutlineInputBorder()),
                  autofocus: true,
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: "Password (optional, can make the loading slower)",
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text("Cancel")),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(context).pop((name, passwordController.text));
                }
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    ).then((_) async {
      if (nameController.text.isEmpty && passwordController.text.isEmpty) return;
      if (passwordController.text.isNotEmpty) {
        // Create passworded folder
        provider.folders.add(Folder(name: nameController.text, encrypted: true));
      } else {
        // Create normal folder
        provider.folders.add(Folder(name: nameController.text, encrypted: false));
      }

      formInputs.first.defaultValue = nameController.text;

      await _recreateFolderList(context);

      controller?.requestUpdate();
    });
  }

  @override
  Future<dynamic> run(BuildContext context, ExecutionContext cache) async {
    NodeEditorController? editor = NodeControls.of(context);
    AppState provider = Inherited.of(context)!;

    List<Node>? incomingNodes = editor?.incomingNodes(this, 0) ?? [];

    for (var node in incomingNodes) {
      PromptResponse result = await node.execute(context, cache);

      debugPrint("Saving to folder ${formInputs.first.defaultValue}");

      var box = provider.boxMap[formInputs.first.defaultValue];

      if (box != null) {
        // Dont save image data to local storage twice
        result.prompt?.clearImages();

        // Add data to local storage
        box.add(
          PromptData(
            width: result.prompt?.width,
            height: result.prompt?.height,
            prompt: result.prompt,
            data: result.images.first,
            name: result.info,
            mimeType: (result.prompt != null && result.prompt!.frames > 0) ? "gif" : "img",
          ),
        );

        provider.requestUpdate();
      } else {
        debugPrint("Failed to save to folder");
      }
    }

    return null;
  }
}
