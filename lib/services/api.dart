import "./server.dart";
import 'dart:async';
import '/models/index.dart';

class KoboldApi extends Server {
  KoboldApi({required super.headers, required super.baseUrl, super.onError});

  Future<dynamic> getModels() async {
    return get("/sdapi/v1/sd-models");
  }

  Future<PromptResponse> postImageToImage(ImagePrompt prompt) async {
    return post("/sdapi/v1/img2img", prompt.toJson()).then((json) => PromptResponse.fromJson(json));
  }

  Future<PromptResponse> postTextToImage(ImagePrompt promp) async {
    return post("/sdapi/v1/txt2img", promp.toJson()).then((json) => PromptResponse.fromJson(json));
  }
}
