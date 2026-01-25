import 'package:flutter/material.dart';
import '/models/index.dart';
import 'package:node_editor/index.dart';
import '/state.dart';
import 'dart:async';

import '/services/server.dart';

class KoboldApi extends Server {
  KoboldApi({required super.headers, required super.baseUrl, super.onError});
  Future<dynamic> getModels() => get("/sdapi/v1/sd-models");
  Future<dynamic> getVersion() => get("/api/extra/version");
  Future<dynamic> getConfigs() => get("/api/admin/list_options").then((value) => value);
  Future<dynamic> changeConfig(String model, String config) =>
      post("/api/admin/reload_config", {"filename": model, "overrideconfig": config}).then((json) => json);
  Future<PromptResponse> postImageToImage(ImagePrompt prompt) =>
      post("/sdapi/v1/img2img", prompt.toJson()).then((json) => PromptResponse.fromJson(json));
  Future<PromptResponse> postTextToImage(ImagePrompt promp) =>
      post("/sdapi/v1/txt2img", promp.toJson()).then((json) => PromptResponse.fromJson(json));
}

List<FormInput> _defaultNodes = [
  FormInput(
    label: "API address",
    type: FormInputType.text,
    width: 300,
    height: 80,
    defaultValue: "http://localhost:5001",
    validator: defaultValidator,
  ),
  FormInput(
    label: "Configs",
    type: FormInputType.dropdown,
    defaultValue: "default",
    width: 300,
    height: 50,
    options: ["default"],
    validator: defaultValidator,
  ),
  FormInput(
    label: "Models",
    type: FormInputType.dropdown,
    defaultValue: "default",
    width: 300,
    height: 50,
    options: ["default"],
    validator: defaultValidator,
  ),
];

class KoboldNode extends FormNode {
  @override
  String get typeName => 'KoboldNode';
  bool loading = false;

  KoboldNode({
    super.color = Colors.orangeAccent,
    super.label = "Kobold API",
    super.size = const Size(400, 400),
    super.inputs = const [Input(label: "Prompt", color: Colors.lightGreen)],
    super.outputs = const [Output(label: "Image", color: Colors.yellow)],
    super.offset,
    super.uuid,
    super.key,
    List<FormInput>? customFormInputs,
  }) : super(formInputs: customFormInputs ?? _defaultNodes);

  factory KoboldNode.fromJson(Map<String, dynamic> json) {
    final data = Node.fromJson(json);
    final formInputs =
        (json["formInputs"] as List<dynamic>?)?.map((i) => FormInput.fromJson(i)).toList() ?? _defaultNodes;

    return KoboldNode(
      size: Size(400, 400),
      label: "Kobold API",
      color: Colors.orangeAccent,
      offset: data.offset,
      inputs: const [Input(label: "Prompt", color: Colors.lightGreen)],
      outputs: const [Output(label: "Image", color: Colors.yellow)],
      uuid: json["uuid"] as String?,
      customFormInputs: formInputs,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    formInputs[1].options = [];
    formInputs[2].options = [];
    return super.toJson();
  }

  @override
  Future<void> init(BuildContext context) async {
    try {
      KoboldApi api = KoboldApi(headers: {}, baseUrl: formInputs.first.controller.text);
      var data = List.from(await api.getConfigs());
      List<String> configs = ["default", ...data.where((item) => item.contains(".kcpps"))];
      List<String> models = ["default", ...data.where((item) => !item.contains(".kcpps"))];

      formInputs = [...formInputs];
      formInputs[1].options = configs;
      formInputs[2].options = models;
    } catch (err) {
      debugPrint("could not connect to kobold api");
    }

    return super.init(context);
  }

  @override
  Future<PromptResponse> run(BuildContext context, ExecutionContext cache) async {
    NodeEditorController? editor = NodeControls.of(context);
    AppState provider = Inherited.of(context)!;

    if (formKey.currentState != null && formKey.currentState!.validate()) {
      KoboldApi api = KoboldApi(headers: {}, baseUrl: formInputs.first.controller.text);
      try {
        var incomingNodes = editor?.incomingNodes(this, 0) ?? [];
        if (incomingNodes.isEmpty) {
          throw Exception("No node connected to Kobold input");
        }

        ImagePrompt prompt = await incomingNodes.first.execute(context, cache);

        // Change the model and wait for server to restart
        if (formInputs[1].defaultValue != "default" && formInputs[2].defaultValue != "default") {
          print("Switching kobold model");
          loading = true;
          editor?.requestUpdate();

          await api.changeConfig(formInputs[2].defaultValue!, formInputs[1].defaultValue!);
          await Future<void>.delayed(const Duration(seconds: 5));
          await waitForServerReady(() => api.getVersion());

          loading = false;
          editor?.requestUpdate();
        }

        var response = await provider.createPromptRequest(prompt, api.postImageToImage(prompt));
        prompt.clearImages();
        response.prompt = prompt;
        return response;
      } catch (err) {
        print(err.toString());
        throw Exception("API execution failed");
      }
    }

    throw Exception("API execution failed");
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: SizedBox(width: 50, height: 20, child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    return Column(
      spacing: 10,
      children: [
        super.build(context),
        Tooltip(
          message: "Only change Configs/Models from default, when you want kobold to make the change (Takes time)",
          child: Icon(Icons.info, color: Colors.black),
        ),
      ],
    );
  }
}
