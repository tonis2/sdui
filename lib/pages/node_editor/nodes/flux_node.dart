import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_nodes/index.dart';
import '/models/index.dart';
import '/state.dart';
import '/services/server.dart';

class FluxApi extends Server {
  FluxApi({required super.headers, required super.baseUrl, super.onError});

  Future<PromptResponse> postImage(ImagePrompt prompt) {
    final body = <String, dynamic>{
      "prompt": prompt.prompt,
      "steps": prompt.steps,
      "seed": prompt.seed,
      "width": prompt.width,
      "height": prompt.height,
    };
    if (prompt.initImages.isNotEmpty) {
      body["init_images"] = prompt.initImages.map(base64.encode).toList();
    }

    // Debug: log the outgoing prompt without dumping image bytes.
    // debugPrint(
    //   '[FluxApi] POST /sdapi/v1/img2img\n'
    //   '  prompt: "${prompt.prompt}"\n'
    //   '  negative: "${prompt.negativePrompt}"\n'
    //   '  sampler: ${prompt.sampler}, scheduler: ${prompt.scheduler}\n'
    //   '  size: ${prompt.width}x${prompt.height}, steps: ${prompt.steps}, seed: ${prompt.seed}\n'
    //   '  guidance: ${prompt.guidance}, denoise: ${prompt.noiseStrenght}, frames: ${prompt.frames}, clipSkip: ${prompt.clipSkip}\n'
    //   '  init_images: ${prompt.initImages.length} [${prompt.initImages.map((i) => "${i.lengthInBytes}B").join(", ")}]\n'
    //   '  extra_images: ${prompt.extraImages.length} [${prompt.extraImages.map((i) => "${i.lengthInBytes}B").join(", ")}]',
    // );

    return post("/sdapi/v1/img2img", body).then((json) {
      final data = json["data"] as String?;
      if (data == null) {
        throw Exception("Flux server returned no image data");
      }
      return PromptResponse(images: [base64Decode(data)]);
    });
  }
}

List<FormInput> _defaultInputs = [
  FormInput(
    label: "API address",
    type: FormInputType.text,
    width: 300,
    height: 80,
    defaultValue: "http://127.0.0.1:7860",
    validator: defaultValidator,
  ),
];

class FluxNode extends FormNode {
  @override
  String get typeName => 'FluxNode';

  FluxNode({
    super.color = Colors.tealAccent,
    super.label = "Flux Runner",
    super.size = const Size(400, 300),
    super.inputs = const [Input(label: "Prompt", color: Colors.lightGreen)],
    super.outputs = const [Output(label: "Image", color: Colors.yellow)],
    super.offset,
    super.uuid,
    super.key,
    List<FormInput>? customFormInputs,
  }) : super(formInputs: customFormInputs ?? _defaultInputs);

  factory FluxNode.fromJson(Map<String, dynamic> json) {
    final data = Node.fromJson(json);
    final formInputs =
        (json["formInputs"] as List<dynamic>?)
            ?.map((i) => FormInput.fromJson(i))
            .toList() ??
        _defaultInputs;

    return FluxNode(
      offset: data.offset,
      uuid: json["uuid"] as String?,
      customFormInputs: formInputs,
    );
  }

  @override
  Future<PromptResponse> run(
    BuildContext context,
    ExecutionContext cache,
  ) async {
    NodeEditorController? editor = NodeControls.of(context);
    AppState provider = Inherited.of(context)!;

    if (formKey.currentState != null && formKey.currentState!.validate()) {
      final api = FluxApi(
        headers: {},
        baseUrl: formInputs.first.controller.text,
      );

      final incoming = editor?.incomingNodes(this, 0) ?? [];
      if (incoming.isEmpty) {
        throw Exception("No node connected to Flux input");
      }

      ImagePrompt prompt = await incoming.first.execute(context, cache);

      final response = await provider.createPromptRequest(
        prompt,
        () => api.postImage(prompt),
      );

      response.prompt = ImagePrompt(
        prompt: prompt.prompt,
        negativePrompt: prompt.negativePrompt,
        steps: prompt.steps,
        width: prompt.width,
        height: prompt.height,
        seed: prompt.seed,
        clipSkip: prompt.clipSkip,
        guidance: prompt.guidance,
        noiseStrenght: prompt.noiseStrenght,
        sampler: prompt.sampler,
        scheduler: prompt.scheduler,
        frames: prompt.frames,
        maskInvert: prompt.maskInvert,
      );
      return response;
    }

    throw Exception("Flux node validation failed");
  }
}
