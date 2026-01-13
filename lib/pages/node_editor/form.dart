import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:math';
import '/state.dart';
import 'package:flutter/services.dart';
import '/components/node_editor/index.dart';

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

class PromptConfig extends Node {
  PromptConfig({
    super.color = Colors.orangeAccent,
    super.label = "Prompt config",
    super.size = const Size(400, 500),
    super.inputs = const [Input(label: "Images")],
    super.outputs = const [Output(label: "Prompt")],
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
  void execute(NodeEditorController controller) {
    print("error");
    super.execute(controller);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Form(
          key: _formKey,
          child: Wrap(spacing: 5, runSpacing: 8, children: formInputs.map((item) => item.build(context)).toList()),
        ),
      ],
    );
  }
}
