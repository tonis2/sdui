import 'package:flutter/material.dart';
import '/models/index.dart';
import '/components/node_editor/index.dart';
import '/state.dart';
import 'dart:async';

import '/services/server.dart';

class KoboldApi extends Server {
  KoboldApi({required super.headers, required super.baseUrl, super.onError});
  Future<dynamic> getModels() => get("/sdapi/v1/sd-models");
  Future<PromptResponse> postImageToImage(ImagePrompt prompt) =>
      post("/sdapi/v1/img2img", prompt.toJson()).then((json) => PromptResponse.fromJson(json));
  Future<PromptResponse> postTextToImage(ImagePrompt promp) =>
      post("/sdapi/v1/txt2img", promp.toJson()).then((json) => PromptResponse.fromJson(json));
}

FormInput _defaultNode = FormInput(
  label: "API address",
  type: FormInputType.text,
  width: 300,
  height: 80,
  defaultValue: "http://localhost:5001",
  validator: defaultValidator,
);

class KoboldNode extends FormNode {
  KoboldNode({
    super.color = Colors.orangeAccent,
    super.label = "Kobold API",
    super.size = const Size(400, 200),
    super.inputs = const [Input(label: "Prompt", color: Colors.lightGreen)],
    super.outputs = const [Output(label: "Image", color: Colors.yellow)],
    super.offset,
    super.uuid,
    super.key,
    List<FormInput>? customFormInputs,
  }) : super(formInputs: customFormInputs ?? [_defaultNode]);

  factory KoboldNode.fromJson(Map<String, dynamic> json) {
    final data = Node.fromJson(json);
    final formInputs =
        (json["formInputs"] as List<dynamic>?)?.map((i) => FormInput.fromJson(i)).toList() ?? [_defaultNode];

    return KoboldNode(
      label: data.label,
      offset: data.offset,
      size: data.size,
      color: data.color,
      inputs: data.inputs,
      outputs: data.outputs,
      uuid: json["uuid"] as String?,
      customFormInputs: formInputs,
    );
  }

  @override
  Future<PromptResponse> executeImpl(BuildContext context) async {
    NodeEditorController? editor = NodeControls.of(context);
    AppState provider = Inherited.of(context)!;

    print("execute kobold");

    if (editor == null) {
      throw Exception("NodeEditorController not found");
    }

    if (formKey.currentState != null && formKey.currentState!.validate()) {
      KoboldApi api = KoboldApi(headers: {}, baseUrl: formInputs.first.controller.text);
      try {
        var incomingNodes = editor.incomingNodes(this, 0);
        if (incomingNodes.isEmpty) {
          throw Exception("No node connected to Prompt input");
        }
        Node node = incomingNodes.first;
        ImagePrompt prompt = await node.execute(context);
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
    ThemeData theme = Theme.of(context);
    return super.build(context);
  }
}
