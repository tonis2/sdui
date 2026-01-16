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
  }) : super(
         formInputs:
             customFormInputs ??
             [
               FormInput(
                 label: "API address",
                 type: FormInputType.text,
                 width: 300,
                 height: 80,
                 defaultValue: "http://localhost:5001",
                 validator: defaultValidator,
               ),
             ],
       );

  factory KoboldNode.fromJson(Map<String, dynamic> json) {
    final data = Node.fromJson(json);
    final formInputs = (json["formInputs"] as List<dynamic>?)?.map((i) => FormInput.fromJson(i)).toList() ?? [];

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
  Future<PromptResponse> execute(BuildContext context) async {
    NodeEditorController? editor = NodeControls.of(context);
    AppState provider = Inherited.of(context)!;

    if (formKey.currentState != null && formKey.currentState!.validate()) {
      KoboldApi api = KoboldApi(headers: {}, baseUrl: formInputs.first.controller.text);
      try {
        Node node = editor!.incomingNodes(this, 0).first;
        ImagePrompt prompt = await node.execute(context);
        var response = await provider.createPromptRequest(prompt, api.postImageToImage(prompt));

        // Save response image to gallery
        if (response.images.isNotEmpty) {
          // painterController.setBackground(newImage);
          provider.images?.add(
            BackgroundImage(
              width: prompt.width,
              height: prompt.height,
              prompt: prompt.prompt,
              data: response.images.first,
              name: response.info,
            ),
          );
        } else {
          debugPrint("Image processing failed");
        }
        print("response received ${response.info}");
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
    return Column(
      spacing: 10,
      children: [
        super.build(context),
        TextButton(
          onPressed: () => execute(context),
          child: Row(
            mainAxisAlignment: .center,
            spacing: 15,
            children: [
              Icon(Icons.send, color: Colors.black),
              Text("Send", style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
