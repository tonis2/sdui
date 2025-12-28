import 'dart:typed_data';
import 'dart:convert';
import 'package:hive_ce/hive.dart';
import 'package:flutter/material.dart';

class ImagePrompt {
  double guidance;
  int steps;
  int width;
  int height;
  int seed;
  int clipSkip;
  double noiseStrenght;
  String sampler;
  String? mask;
  List<Uint8List> initImages = [];
  List<Uint8List> extraImages = [];
  bool maskInvert;

  String prompt;
  String negativePrompt;

  ImagePrompt({
    required this.prompt,
    required this.negativePrompt,
    this.steps = 20,
    this.width = 512,
    this.height = 512,
    this.mask,
    this.seed = -1,
    this.clipSkip = -1,
    this.guidance = 1,
    this.noiseStrenght = 0.6,
    this.sampler = "euler",
    this.maskInvert = false,
  });

  factory ImagePrompt.fromJson(Map<String, dynamic> json) {
    return ImagePrompt(
      prompt: json["prompt"],
      negativePrompt: json["negative_prompt"],
      steps: json["steps"],
      width: json["width"],
      height: json["height"],
      seed: json["seed"],
      clipSkip: json["clip_skip"],
      sampler: json["sampler_name"],
      noiseStrenght: json["denoising_strength"],
      mask: json["mask"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "prompt": prompt,
      "negative_prompt": negativePrompt,
      "cfg_scale": guidance,
      "steps": steps,
      "width": width,
      "height": height,
      "seed": seed,
      "clip_skip": clipSkip,
      "sampler_name": sampler,
      "denoising_strength": noiseStrenght,
      "mask": mask,
      "init_images": List.from(initImages.map<String>((image) => base64.encode(image))),
      "extra_images": List.from(extraImages.map<String>((image) => base64.encode(image))),
      "inpainting_mask_invert": maskInvert,
      "n": guidance,
    };
  }

  void addExtraImage(Uint8List data) {
    extraImages.add(data);
  }

  void addInitImage(Uint8List data) {
    initImages.add(data);
  }

  void clearImages() {
    extraImages.clear();
    initImages.clear();
  }
}

class PromptResponse {
  List<Uint8List> images = [];
  Map<String, dynamic>? parameters;
  String? info;

  PromptResponse({required this.images, this.parameters, this.info});

  factory PromptResponse.fromJson(Map<String, dynamic> json) {
    return PromptResponse(
      images: List.from(json["images"].map((img) => base64Decode(img))),
      parameters: json["parameters"],
      info: json["info"],
    );
  }
}

class BackgroundImage {
  int width;
  int height;
  final int key;
  final Uint8List data;
  final String? mimeType;
  final String? name;
  final String date = DateTime.now().toString();

  BackgroundImage({
    required this.width,
    required this.height,
    required this.data,
    this.name,
    this.mimeType,
    this.key = 0,
  });

  factory BackgroundImage.fromJson(dynamic json) {
    return BackgroundImage(
      width: json["width"],
      height: json["height"],
      data: json["data"],
      mimeType: json["mimeType"],
      name: json["name"],
      key: json["key"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "width": width,
      "height": height,
      "data": data,
      "mimeType": mimeType,
      "name": name,
      "date": date,
      "key": key,
    };
  }
}

class ImageAdapter extends TypeAdapter<BackgroundImage> {
  @override
  final typeId = 0;

  @override
  BackgroundImage read(BinaryReader reader) {
    return BackgroundImage.fromJson(reader.read());
  }

  @override
  void write(BinaryWriter writer, BackgroundImage obj) {
    writer.write(obj.toJson());
  }
}
