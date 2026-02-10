import 'package:flutter/material.dart';
import '/models/index.dart';
import 'package:easy_nodes/index.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '/state.dart';

const _host = 'hunyuan.intl.tencentcloudapi.com';
const _apiVersion = '2023-09-01';

class HunyuanApi {
  final String secretId;
  final String secretKey;
  final http.Client _client = http.Client();

  final String region;

  HunyuanApi({required this.secretId, required this.secretKey, this.region = 'ap-singapore'});

  List<int> _sign(List<int> key, String msg) {
    return Hmac(sha256, key).convert(utf8.encode(msg)).bytes;
  }

  Map<String, String> _buildAuthHeaders(String action, String body) {
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final date = DateTime.fromMillisecondsSinceEpoch(
      int.parse(timestamp) * 1000,
      isUtc: true,
    ).toIso8601String().substring(0, 10);

    final hashedBody = sha256.convert(utf8.encode(body)).toString();

    final canonicalRequest = 'POST\n/\n\ncontent-type:application/json\nhost:$_host\n\ncontent-type;host\n$hashedBody';

    final credentialScope = '$date/hunyuan/tc3_request';
    final hashedCanonical = sha256.convert(utf8.encode(canonicalRequest)).toString();
    final stringToSign = 'TC3-HMAC-SHA256\n$timestamp\n$credentialScope\n$hashedCanonical';

    final secretDate = _sign(utf8.encode('TC3$secretKey'), date);
    final secretService = _sign(secretDate, 'hunyuan');
    final signingKey = _sign(secretService, 'tc3_request');
    final signature = Hmac(sha256, signingKey).convert(utf8.encode(stringToSign)).toString();

    final authorization =
        'TC3-HMAC-SHA256 Credential=$secretId/$credentialScope, SignedHeaders=content-type;host, Signature=$signature';

    return {
      'Authorization': authorization,
      'Content-Type': 'application/json',
      'Host': _host,
      'X-TC-Action': action,
      'X-TC-Timestamp': timestamp,
      'X-TC-Version': _apiVersion,
      'X-TC-Region': region,
    };
  }

  Future<Map<String, dynamic>> _post(String action, Map<String, dynamic> body) async {
    final bodyStr = jsonEncode(body);
    final headers = _buildAuthHeaders(action, bodyStr);

    final response = await _client.post(Uri.parse('https://$_host/'), headers: headers, body: bodyStr);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final responseData = json['Response'] as Map<String, dynamic>;

    if (responseData.containsKey('Error')) {
      final error = responseData['Error'] as Map<String, dynamic>;
      throw Exception('Hunyuan API error: ${error['Code']} - ${error['Message']}');
    }

    return responseData;
  }

  Future<String> submitJob({
    required String imageBase64,
    String? generateType,
    int? faceCount,
    bool? enablePBR,
    String? polygonType,
  }) async {
    final body = <String, dynamic>{'ImageBase64': imageBase64};
    if (generateType != null) body['GenerateType'] = generateType;
    if (faceCount != null) body['FaceCount'] = faceCount;
    if (enablePBR != null) body['EnablePBR'] = enablePBR;
    if (polygonType != null) body['PolygonType'] = polygonType;

    final response = await _post('SubmitHunyuanTo3DProJob', body);
    return response['JobId'] as String;
  }

  Future<Map<String, dynamic>> queryJob(String jobId) async {
    final response = await _post('QueryHunyuanTo3DProJob', {'JobId': jobId});
    return response;
  }
}

List<FormInput> _defaultFormInputs = [
  FormInput(label: "SecretId", type: FormInputType.text, width: 300, height: 80, validator: defaultValidator),
  FormInput(label: "SecretKey", type: FormInputType.text, width: 300, height: 80, validator: defaultValidator),
  FormInput(
    label: "GenerateType",
    type: FormInputType.dropdown,
    width: 300,
    height: 50,
    defaultValue: "Normal",
    options: ["Normal", "LowPoly", "Geometry", "Sketch"],
  ),
  FormInput(label: "FaceCount", type: FormInputType.int, width: 150, height: 60, defaultValue: "250000"),
  FormInput(
    label: "EnablePBR",
    type: FormInputType.dropdown,
    width: 150,
    height: 50,
    defaultValue: "false",
    options: ["false", "true"],
  ),
  FormInput(
    label: "PolygonType",
    type: FormInputType.dropdown,
    width: 150,
    height: 50,
    defaultValue: "triangle",
    options: ["triangle", "quadrilateral"],
  ),
];

class HunyuanNode extends FormNode {
  @override
  String get typeName => 'HunyuanNode';

  HunyuanNode({
    super.color = Colors.deepPurpleAccent,
    super.label = "Hunyuan 3D",
    super.size = const Size(400, 400),
    super.inputs = const [Input(label: "Image", color: Colors.yellow)],
    super.outputs = const [Output(label: "Result", color: Colors.yellow)],
    super.offset,
    super.uuid,
    super.key,
    List<FormInput>? customFormInputs,
  }) : super(formInputs: customFormInputs ?? _defaultFormInputs);

  factory HunyuanNode.fromJson(Map<String, dynamic> json) {
    final data = Node.fromJson(json);
    final formInputs =
        (json["formInputs"] as List<dynamic>?)?.map((i) => FormInput.fromJson(i)).toList() ?? _defaultFormInputs;

    return HunyuanNode(
      size: const Size(400, 400),
      label: "Hunyuan 3D",
      color: Colors.deepPurpleAccent,
      offset: data.offset,
      inputs: const [Input(label: "Image", color: Colors.yellow)],
      outputs: const [Output(label: "Result", color: Colors.yellow)],
      uuid: json["uuid"] as String?,
      customFormInputs: formInputs,
    );
  }

  Future<PromptResponse> _executeJob(HunyuanApi api, String imageBase64) async {
    final generateType = formInputs[2].defaultValue;
    final faceCount = int.tryParse(formInputs[3].controller.text);
    final enablePBR = formInputs[4].defaultValue == "true" ? true : null;
    final polygonType = formInputs[5].defaultValue;

    final jobId = await api.submitJob(
      imageBase64: imageBase64,
      generateType: generateType != "Normal" ? generateType : null,
      faceCount: faceCount,
      enablePBR: enablePBR,
      polygonType: polygonType != "triangle" ? polygonType : null,
    );

    // Poll for results
    while (true) {
      await Future.delayed(const Duration(seconds: 5));

      final result = await api.queryJob(jobId);
      final status = result['Status'] as String?;

      if (status == 'DONE' || status == 'done') {
        final files = result['ResultFile3Ds'] as List<dynamic>?;

        final client = http.Client();
        final images = <Uint8List>[];
        String? glbFileName;

        if (files != null) {
          for (final file in files) {
            final fileMap = file as Map<String, dynamic>;
            final previewUrl = fileMap['PreviewImageUrl'] as String?;
            final modelUrl = fileMap['Url'] as String?;

            // Download preview image
            if (previewUrl != null && previewUrl.isNotEmpty && images.isEmpty) {
              final previewResponse = await client.get(Uri.parse(previewUrl));
              images.add(Uint8List.fromList(previewResponse.bodyBytes));
            }

            // Download 3D model file
            if (modelUrl != null && modelUrl.isNotEmpty) {
              final modelResponse = await client.get(Uri.parse(modelUrl));
              images.add(Uint8List.fromList(modelResponse.bodyBytes));
              glbFileName ??= Uri.parse(modelUrl).pathSegments.lastOrNull ?? 'model.glb';
            }
          }
        }

        client.close();

        if (images.isEmpty) {
          throw Exception("No results returned from Hunyuan API");
        }

        return PromptResponse(images: images, info: glbFileName);
      } else if (status == 'FAIL' || status == 'fail') {
        final errorMsg = result['ErrorMessage'] as String? ?? 'Job failed';
        throw Exception('Hunyuan job failed: $errorMsg');
      }
    }
  }

  @override
  Future<PromptResponse> run(BuildContext context, ExecutionContext cache) async {
    NodeEditorController? editor = NodeControls.of(context);
    AppState provider = Inherited.of(context)!;

    if (formKey.currentState != null && formKey.currentState!.validate()) {
      final api = HunyuanApi(secretId: formInputs[0].controller.text, secretKey: formInputs[1].controller.text);

      var incomingNodes = editor?.incomingNodes(this, 0) ?? [];
      if (incomingNodes.isEmpty) {
        throw Exception("No node connected to Hunyuan input");
      }

      PromptResponse upstream = await incomingNodes.first.execute(context, cache);
      final imageBase64 = base64Encode(upstream.images.first);

      provider.enqueueRequest(() => _executeJob(api, imageBase64), image: upstream.images.first);

      return PromptResponse(images: [upstream.images.first]);
    }

    throw Exception("Form validation failed");
  }
}
