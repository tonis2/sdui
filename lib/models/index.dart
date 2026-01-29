import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:hive_ce/hive.dart';
import 'package:flutter/material.dart';

class ImagePrompt extends HiveObject {
  double guidance;
  int steps;
  int width;
  int height;
  int seed;
  int clipSkip;
  int frames;
  double noiseStrenght;
  String scheduler;
  String sampler;
  Uint8List? mask;
  List<Uint8List> initImages = [];
  List<Uint8List> extraImages = [];
  bool maskInvert;

  String prompt;
  String negativePrompt;

  ImagePrompt({
    required this.prompt,
    required this.negativePrompt,
    this.steps = 8,
    this.width = 512,
    this.height = 512,
    this.frames = 0,
    this.scheduler = "default",
    this.mask,
    this.seed = -1,
    this.clipSkip = 0,
    this.guidance = 1,
    this.noiseStrenght = 0.15,
    this.sampler = "Euler",
    this.maskInvert = false,
  });

  factory ImagePrompt.fromJson(dynamic json) {
    return ImagePrompt(
      prompt: json["prompt"],
      negativePrompt: json["negative_prompt"],
      steps: json["steps"],
      width: json["width"],
      height: json["height"],
      seed: json["seed"],
      clipSkip: json["clip_skip"],
      sampler: json["sampler_name"],
      scheduler: json["scheduler"],
      noiseStrenght: json["denoising_strength"],
      mask: json["mask"],
      frames: json["frames"],
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
      "scheduler": scheduler,
      "denoising_strength": noiseStrenght,
      "mask": mask != null ? base64.encode(mask!) : null,
      "init_images": List.from(initImages.map<String>((image) => base64.encode(image))),
      "extra_images": List.from(extraImages.map<String>((image) => base64.encode(image))),
      "inpainting_mask_invert": maskInvert,
      "n": guidance,
      "frames": frames,
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
    mask = null;
  }
}

class PromptResponse {
  List<Uint8List> images = [];
  Map<String, dynamic>? parameters;
  String? info;
  ImagePrompt? prompt;

  PromptResponse({required this.images, this.parameters, this.info, this.prompt});

  factory PromptResponse.fromJson(Map<String, dynamic> json) {
    return PromptResponse(
      images: List.from(json["images"].map((img) => base64Decode(img))),
      parameters: json["parameters"],
      info: json["info"],
    );
  }
}

@immutable
class PromptData extends HiveObject {
  int? width;
  int? height;
  final Uint8List data;
  final String? mimeType;
  final String? name;
  final ImagePrompt? prompt;
  final String date = DateTime.now().toString();

  PromptData({this.width, this.height, required this.data, this.name, this.mimeType, this.prompt});

  factory PromptData.fromJson(dynamic json) {
    return PromptData(
      width: json["width"],
      height: json["height"],
      data: json["data"],
      mimeType: json["mimeType"],
      prompt: json["prompt"],
      name: json["name"],
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
      "prompt": prompt,
    };
  }
}

@immutable
class Config extends HiveObject {
  final String name;
  final String data;
  final String date = DateTime.now().toString();

  Config({required this.name, required this.data});

  factory Config.fromJson(dynamic json) {
    return Config(name: json["name"], data: json["data"]);
  }

  Map<String, dynamic> toJson() {
    return {"name": name, "data": data, "date": date};
  }
}

@immutable
class Folder extends HiveObject {
  final String name;
  final bool encrypted;
  int size;
  final String date = DateTime.now().toString();

  Folder({required this.name, required this.encrypted, this.size = 0});

  factory Folder.fromJson(dynamic json) {
    return Folder(name: json["name"], encrypted: json["encrypted"]);
  }

  Map<String, dynamic> toJson() {
    return {"name": name, "encrypted": encrypted, "date": date};
  }
}

class ImagePromptAdapter extends TypeAdapter<ImagePrompt> {
  @override
  final typeId = 3;

  @override
  ImagePrompt read(BinaryReader reader) {
    return ImagePrompt.fromJson(reader.read());
  }

  @override
  void write(BinaryWriter writer, ImagePrompt obj) {
    writer.write(obj.toJson());
  }
}

class ConfigAdapter extends TypeAdapter<Config> {
  @override
  final typeId = 2;

  @override
  Config read(BinaryReader reader) {
    return Config.fromJson(reader.read());
  }

  @override
  void write(BinaryWriter writer, Config obj) {
    writer.write(obj.toJson());
  }
}

class FolderAdapter extends TypeAdapter<Folder> {
  @override
  final typeId = 1;

  @override
  Folder read(BinaryReader reader) {
    return Folder.fromJson(reader.read());
  }

  @override
  void write(BinaryWriter writer, Folder obj) {
    writer.write(obj.toJson());
  }
}

class ImageAdapter extends TypeAdapter<PromptData> {
  @override
  final typeId = 0;

  @override
  PromptData read(BinaryReader reader) {
    return PromptData.fromJson(reader.read());
  }

  @override
  void write(BinaryWriter writer, PromptData obj) {
    writer.write(obj.toJson());
  }
}

@immutable
class QueueItem {
  final Future<dynamic> Function() promptRequest;
  DateTime? endTime;
  DateTime? startTime;
  Uint8List? image;
  bool active;
  Completer response;

  QueueItem({this.endTime, required this.promptRequest, required this.response, this.image, this.active = false});
}
