import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sdui/models/index.dart';
import 'dart:math';
import '/state.dart';
import 'package:flutter/services.dart';
import '/components/node_editor/index.dart';
import 'dart:ui' as ui;
import 'nodes.dart';

enum FormInputType { text, textArea, range, int, double }

OutlineInputBorder inputBorder = OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1));
FilteringTextInputFormatter doubleInputFilter = FilteringTextInputFormatter.allow(RegExp(r'(^\d*[\.]?\d{0,2})'));

class FormInput {
  String label;
  int min;
  int max;
  double width;
  double height;
  FormInputType type;
  TextEditingController controller = TextEditingController();
  String? defaultValue;
  FormInput({
    required this.label,
    required this.type,
    this.min = 64,
    this.max = 1024,
    this.width = 100,
    this.height = 60,
    this.defaultValue,
  }) {
    if (defaultValue != null) controller = TextEditingController(text: defaultValue);
  }

  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    TextStyle? inputText = theme.textTheme.bodyMedium;

    switch (type) {
      case .textArea || .text:
        {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
            padding: EdgeInsets.all(8),
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(label: Text(label, style: inputText)),
              minLines: type == .text ? 1 : 2,
              maxLines: type == .text ? 1 : 10,
              keyboardType: type == .text ? TextInputType.text : TextInputType.multiline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a prompt';
                }
                return null;
              },
            ),
          );
        }

      case .int || .double:
        {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
            padding: EdgeInsets.all(8),
            child: TextFormField(
              inputFormatters: [type == .double ? doubleInputFilter : FilteringTextInputFormatter.digitsOnly],
              controller: controller,
              decoration: InputDecoration(label: Text(label, style: inputText)),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a prompt';
                }
                return null;
              },
            ),
          );
        }

      case .range:
        {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
            padding: EdgeInsets.all(8),
            child: TextFormField(
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              controller: controller,
              decoration: InputDecoration(label: Text(label, style: inputText)),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a prompt';
                }
                return null;
              },
            ),
          );
        }
    }
  }
}

class PromptConfig extends Node<ImagePrompt> {
  PromptConfig({
    super.color = Colors.orangeAccent,
    super.label = "Prompt config",
    super.size = const Size(400, 600),
    super.inputs = const [
      Input(label: "Extra images", color: Colors.yellow),
      Input(label: "Init images", color: Colors.yellow),
    ],
    super.outputs = const [Output(label: "Prompt", color: Colors.lightGreen)],
    super.offset,
    super.key,
  });

  List<FormInput> formInputs = [
    FormInput(label: "Prompt", type: .textArea, width: 350, height: 100),
    FormInput(label: "Negative prompt", type: .textArea, width: 350, height: 100),
    FormInput(label: "Seed", type: .int, defaultValue: "-1"),
    FormInput(label: "Sampler", type: .text, defaultValue: "euler"),
    FormInput(label: "Steps", type: .int, defaultValue: "8"),
    FormInput(label: "Guidance", type: .double, defaultValue: "1"),
    FormInput(label: "Denoise", type: .double, defaultValue: "0.3"),
    FormInput(label: "Scheduler", type: .text, defaultValue: "default"),
    FormInput(label: "Frames", type: .int, defaultValue: "0"),
    FormInput(label: "Clip skip", type: .int, defaultValue: "0"),
    FormInput(label: "Width", type: .range, defaultValue: "1024", width: 175),
    FormInput(label: "Height", type: .range, defaultValue: "1024", width: 175),
  ];

  final _formKey = GlobalKey<FormState>();

  @override
  Future<ImagePrompt> execute(BuildContext context) async {
    NodeEditorController? provider = NodeControls.of(context);

    ImagePrompt prompt = ImagePrompt(
      prompt: formInputs[0].controller.text,
      negativePrompt: formInputs[1].controller.text,
      seed: int.parse(formInputs[2].controller.text),
      sampler: formInputs[3].controller.text,
      steps: int.parse(formInputs[4].controller.text),
      guidance: double.parse(formInputs[5].controller.text),
      noiseStrenght: double.parse(formInputs[6].controller.text),
      frames: int.parse(formInputs[8].controller.text),
      clipSkip: int.parse(formInputs[9].controller.text),
      width: int.parse(formInputs[10].controller.text),
      height: int.parse(formInputs[11].controller.text),
    );

    try {
      for (var node in provider!.incomingNodes<ImageOutput>(this, 0)) {
        ImageOutput image = await node.execute(context);
        prompt.extraImages.add(image.data);
      }

      for (var node in provider.incomingNodes<ImageOutput>(this, 1)) {
        ImageOutput image = await node.execute(context);
        prompt.initImages.add(image.data);
      }
    } catch (err) {
      print(err.toString());
    }

    return prompt;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Column(
      children: [
        Form(
          key: _formKey,
          child: SizedBox(
            width: size.width,
            height: size.height - 40,
            child: Wrap(spacing: 5, runSpacing: 8, children: formInputs.map((item) => item.build(context)).toList()),
          ),
        ),
      ],
    );
  }
}
