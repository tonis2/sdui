import 'package:flutter/material.dart';
import '/components/node_editor/index.dart';
import 'package:hive_ce/hive_ce.dart';
import '/models/index.dart';

class FolderNode extends FormNode {
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
  }) : super(
         formInputs:
             customFormInputs ??
             [
               FormInput(
                 label: "Folder name",
                 type: FormInputType.dropdown,
                 width: 300,
                 height: 80,
                 options: [],
                 validator: defaultValidator,
               ),
             ],
       );

  factory FolderNode.fromJson(Map<String, dynamic> json) {
    final data = Node.fromJson(json);
    final formInputs = (json["formInputs"] as List<dynamic>?)?.map((i) => FormInput.fromJson(i)).toList() ?? [];
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

  Future<void> _recreateFolderList(Box<Folder> folders) async {
    String? defaultValue;
    if (formInputs.isNotEmpty) {
      defaultValue = formInputs.first.defaultValue;
    }

    formInputs = [
      FormInput(
        label: "Folders",
        type: FormInputType.dropdown,
        defaultValue: defaultValue,
        width: 300,
        height: 80,
        options: folders.values.map((value) => value.name).toList(),
        validator: defaultValidator,
      ),
    ];
  }

  @override
  Future<void> init() async {
    Box<Folder> folders = await Hive.openBox('folders');
    await _recreateFolderList(folders);
    return super.init();
  }

  void createFolder(BuildContext context) {
    NodeEditorController? provider = NodeControls.of(context);
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
                  decoration: const InputDecoration(labelText: "Password (optional)", border: OutlineInputBorder()),
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

      Box<Folder> folders = await Hive.openBox('folders');
      if (passwordController.text.isNotEmpty) {
        // Create passworded folder
        folders.add(Folder(name: nameController.text, encrypted: true));
      } else {
        // Create normal folder
        folders.add(Folder(name: nameController.text, encrypted: false));
      }

      await _recreateFolderList(folders);

      provider?.requestUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ThemeData theme = Theme.of(context);
    // NodeEditorController? provider = NodeControls.of(context);

    return Column(
      spacing: 10,
      children: [
        super.build(context),
        TextButton(onPressed: () => createFolder(context), child: const Text("Create new folder")),
        SizedBox(height: 10),
      ],
    );
  }
}
