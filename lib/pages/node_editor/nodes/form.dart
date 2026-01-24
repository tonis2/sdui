import 'package:flutter/material.dart';
import '/models/index.dart';
import '/components/node_editor/index.dart';
import 'image.dart';

List<FormInput> defaultFormInputs = [
  FormInput(
    label: "Prompt",
    type: FormInputType.textArea,
    width: 450,
    height: 100,
    minLines: 4,
    maxLines: 10,
    validator: defaultValidator,
  ),
  FormInput(label: "Negative prompt", type: FormInputType.textArea, width: 450, height: 100, minLines: 4, maxLines: 10),
  FormInput(
    width: 221,
    height: 60,
    label: "Sampler",
    type: FormInputType.dropdown,
    defaultValue: "Euler",
    options: ["Euler", "Euler a", "Heun", "DPM2", "DPM++2M", "DDIM", "LCM"],
  ),
  FormInput(
    width: 221,
    height: 60,
    label: "Scheduler",
    type: FormInputType.dropdown,
    defaultValue: "default",
    options: ["default", "discrete", "karras", "exponential", "ays", "gits", "sgm_uniform", "simple", "smoothstep"],
  ),
  FormInput(label: "Width", type: FormInputType.range, defaultValue: "1024", width: 220),
  FormInput(label: "Height", type: FormInputType.range, defaultValue: "1024", width: 220),
  FormInput(label: "Seed", type: FormInputType.int, defaultValue: "-1"),
  FormInput(label: "Steps", type: FormInputType.int, defaultValue: "8"),
  FormInput(label: "Guidance", type: FormInputType.double, defaultValue: "1"),
  FormInput(label: "Denoise", type: FormInputType.double, defaultValue: "0.3"),
  FormInput(label: "Frames", type: FormInputType.int, defaultValue: "0"),
  FormInput(label: "Clip skip", type: FormInputType.int, defaultValue: "0"),
];

class PromptNode extends FormNode {
  PromptNode({
    super.color = Colors.orangeAccent,
    super.label = "Prompt config",
    super.size = const Size(500, 500),
    super.inputs = const [
      Input(label: "Extra images", color: Colors.yellow),
      Input(label: "Init images", color: Colors.yellow),
    ],
    super.outputs = const [Output(label: "Prompt", color: Colors.lightGreen)],
    super.offset,
    super.uuid,
    super.key,
    List<FormInput>? customFormInputs,
  }) : super(formInputs: customFormInputs ?? defaultFormInputs);

  factory PromptNode.fromJson(Map<String, dynamic> json) {
    final data = Node.fromJson(json);
    final formInputs =
        (json["formInputs"] as List<dynamic>?)?.map((i) => FormInput.fromJson(i)).toList() ?? defaultFormInputs;

    return PromptNode(
      label: "Prompt config",
      size: const Size(500, 500),
      color: Colors.lightGreen,
      inputs: const [
        Input(label: "Extra images", color: Colors.yellow),
        Input(label: "Init images", color: Colors.yellow),
      ],
      outputs: const [Output(label: "Prompt", color: Colors.lightGreen)],
      offset: data.offset,
      uuid: data.uuid,
      customFormInputs: formInputs,
    );
  }

  @override
  Future<ImagePrompt> executeImpl(BuildContext context) async {
    NodeEditorController? provider = NodeControls.of(context);
    ImagePrompt prompt = ImagePrompt(
      prompt: formInputs[0].controller.text,
      negativePrompt: formInputs[1].controller.text,
      sampler: formInputs[2].controller.text,
      scheduler: formInputs[3].controller.text,
      width: int.parse(formInputs[4].controller.text),
      height: int.parse(formInputs[5].controller.text),
      seed: int.parse(formInputs[6].controller.text),
      steps: int.parse(formInputs[7].controller.text),
      guidance: double.parse(formInputs[8].controller.text),
      noiseStrenght: double.parse(formInputs[9].controller.text),
      frames: int.parse(formInputs[10].controller.text),
      clipSkip: int.parse(formInputs[11].controller.text),
    );

    if (formKey.currentState != null && formKey.currentState!.validate()) {
      try {
        for (var node in provider!.incomingNodes(this, 0)) {
          ImageOutput image = await node.execute(context);
          prompt.extraImages.add(image.data);
        }

        for (var node in provider.incomingNodes(this, 1)) {
          ImageOutput image = await node.execute(context);
          prompt.initImages.add(image.data);
        }

        return prompt;
      } catch (err) {
        print(err.toString());
      }
    }

    throw Exception("Prompt form execution failed");
  }
}
