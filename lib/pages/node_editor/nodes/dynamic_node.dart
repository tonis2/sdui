import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:easy_nodes/index.dart';
import 'package:http/http.dart' as http;
import '/models/index.dart';
import '/state.dart';

// --- Icon mapping ---

const Map<String, IconData> iconMap = {
  'public': Icons.public,
  'auto_awesome': Icons.auto_awesome,
  'smart_toy': Icons.smart_toy,
  'view_in_ar': Icons.view_in_ar,
  'image': Icons.image,
  'api': Icons.api,
  'cloud': Icons.cloud,
  'extension': Icons.extension,
  'memory': Icons.memory,
  'hub': Icons.hub,
  'bolt': Icons.bolt,
  'brush': Icons.brush,
  'palette': Icons.palette,
  'music_note': Icons.music_note,
  'videocam': Icons.videocam,
  'text_fields': Icons.text_fields,
  'code': Icons.code,
  'science': Icons.science,
  'psychology': Icons.psychology,
  'edit_note': Icons.edit_note,
  'folder': Icons.folder,
};

// --- JSON path resolution ---

/// Simplified JSON path: dot-notation + array wildcards.
///  - `$.field` -> json['field']
///  - `$.field.nested` -> json['field']['nested']
///  - `$.array[*].url` -> json['array'].map((e) => e['url'])
///  - `$[*].url` -> (top-level list).map((e) => e['url'])
dynamic resolveJsonPath(dynamic json, String path) {
  if (!path.startsWith(r'$')) return null;
  // Strip leading '$' and optional leading '.'
  var remainder = path.substring(1);
  if (remainder.startsWith('.')) remainder = remainder.substring(1);
  if (remainder.isEmpty) return json;
  return _resolve(json, remainder);
}

dynamic _resolve(dynamic current, String path) {
  if (current == null) return null;
  if (path.isEmpty) return current;

  // Handle [*] wildcard at the start
  if (path.startsWith('[*]')) {
    if (current is! List) return null;
    final rest = path.substring(3);
    final nextPath = rest.startsWith('.') ? rest.substring(1) : rest;
    if (nextPath.isEmpty) return current;
    return current.map((e) => _resolve(e, nextPath)).toList();
  }

  // Split on first '.' or '[*]'
  final wildcardIdx = path.indexOf('[*]');
  final dotIdx = path.indexOf('.');

  int splitAt;
  if (wildcardIdx == -1 && dotIdx == -1) {
    // No more separators — leaf key
    if (current is Map) return current[path];
    return null;
  } else if (wildcardIdx != -1 && (dotIdx == -1 || wildcardIdx < dotIdx)) {
    splitAt = wildcardIdx;
  } else {
    splitAt = dotIdx;
  }

  final key = path.substring(0, splitAt);
  var rest = path.substring(splitAt);
  if (rest.startsWith('.')) rest = rest.substring(1);

  if (current is Map) {
    return _resolve(current[key], rest);
  }
  return null;
}

// --- Template resolution ---

/// Resolve `{{...}}` templates inside a value tree.
/// If an entire string value is a single template, it resolves to the typed value.
/// Otherwise templates embedded in a larger string resolve via concatenation.
dynamic resolveTemplates(dynamic value, Map<String, dynamic> context) {
  if (value is String) {
    return _resolveStringTemplate(value, context);
  }
  if (value is Map) {
    return value.map((k, v) => MapEntry(k, resolveTemplates(v, context)));
  }
  if (value is List) {
    return value.map((v) => resolveTemplates(v, context)).toList();
  }
  return value;
}

final _templatePattern = RegExp(r'\{\{(.+?)\}\}');

dynamic _resolveStringTemplate(String template, Map<String, dynamic> context) {
  final matches = _templatePattern.allMatches(template).toList();
  if (matches.isEmpty) return template;

  // If the entire string is a single template, resolve to the typed value
  if (matches.length == 1 && matches.first.start == 0 && matches.first.end == template.length) {
    return _resolveVariable(matches.first.group(1)!, context);
  }

  // Otherwise, string concatenation
  final buf = StringBuffer();
  var lastEnd = 0;
  for (final m in matches) {
    buf.write(template.substring(lastEnd, m.start));
    final resolved = _resolveVariable(m.group(1)!, context);
    buf.write(resolved?.toString() ?? '');
    lastEnd = m.end;
  }
  buf.write(template.substring(lastEnd));
  return buf.toString();
}

dynamic _resolveVariable(String expr, Map<String, dynamic> context) {
  // Check for type coercion suffix: `:int`, `:double`, `:bool`
  String? typeSuffix;
  var varPath = expr.trim();

  final colonIdx = varPath.lastIndexOf(':');
  if (colonIdx > 0) {
    final suffix = varPath.substring(colonIdx + 1);
    if (suffix == 'int' || suffix == 'double' || suffix == 'bool') {
      typeSuffix = suffix;
      varPath = varPath.substring(0, colonIdx);
    }
  }

  // Navigate context with dot notation: "form.Label" -> context['form']['Label']
  dynamic value;
  final parts = varPath.split('.');
  value = context;
  for (final part in parts) {
    if (value is Map) {
      value = value[part];
    } else {
      value = null;
      break;
    }
  }

  if (value == null) return null;

  // Apply type coercion
  final str = value.toString();
  switch (typeSuffix) {
    case 'int':
      return int.tryParse(str) ?? 0;
    case 'double':
      return double.tryParse(str) ?? 0.0;
    case 'bool':
      return str.toLowerCase() == 'true';
    default:
      return value;
  }
}

// --- Config models ---

class RequestConfig {
  final String url;
  final String method;
  final Map<String, dynamic> headers;
  final Map<String, dynamic>? body;

  RequestConfig({required this.url, required this.method, required this.headers, this.body});

  factory RequestConfig.fromJson(Map<String, dynamic> json) {
    return RequestConfig(
      url: json['url'] as String,
      method: (json['method'] as String?) ?? 'POST',
      headers: Map<String, dynamic>.from(json['headers'] ?? {}),
      body: json['body'] != null ? Map<String, dynamic>.from(json['body']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'method': method,
    'headers': headers,
    if (body != null) 'body': body,
  };
}

class ResponseConfig {
  final String? images;
  final String? imageEncoding;
  final String? info;

  ResponseConfig({this.images, this.imageEncoding, this.info});

  factory ResponseConfig.fromJson(Map<String, dynamic> json) {
    return ResponseConfig(
      images: json['images'] as String?,
      imageEncoding: json['imageEncoding'] as String?,
      info: json['info'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (images != null) 'images': images,
    if (imageEncoding != null) 'imageEncoding': imageEncoding,
    if (info != null) 'info': info,
  };
}

class PollingConfig {
  final String submitUrl;
  final Map<String, dynamic>? submitBody;
  final String jobIdPath;
  final String queryUrl;
  final Map<String, dynamic>? queryBody;
  final String statusPath;
  final String doneValue;
  final String? failValue;
  final String? resultPath;
  final String? resultImagePath;
  final String? resultFilePath;
  final int intervalSeconds;

  PollingConfig({
    required this.submitUrl,
    this.submitBody,
    required this.jobIdPath,
    required this.queryUrl,
    this.queryBody,
    required this.statusPath,
    required this.doneValue,
    this.failValue,
    this.resultPath,
    this.resultImagePath,
    this.resultFilePath,
    this.intervalSeconds = 5,
  });

  factory PollingConfig.fromJson(Map<String, dynamic> json) {
    return PollingConfig(
      submitUrl: json['submitUrl'] as String,
      submitBody: json['submitBody'] != null ? Map<String, dynamic>.from(json['submitBody']) : null,
      jobIdPath: json['jobIdPath'] as String,
      queryUrl: json['queryUrl'] as String,
      queryBody: json['queryBody'] != null ? Map<String, dynamic>.from(json['queryBody']) : null,
      statusPath: json['statusPath'] as String,
      doneValue: json['doneValue'] as String,
      failValue: json['failValue'] as String?,
      resultPath: json['resultPath'] as String?,
      resultImagePath: json['resultImagePath'] as String?,
      resultFilePath: json['resultFilePath'] as String?,
      intervalSeconds: (json['intervalSeconds'] as int?) ?? 5,
    );
  }

  Map<String, dynamic> toJson() => {
    'submitUrl': submitUrl,
    if (submitBody != null) 'submitBody': submitBody,
    'jobIdPath': jobIdPath,
    'queryUrl': queryUrl,
    if (queryBody != null) 'queryBody': queryBody,
    'statusPath': statusPath,
    'doneValue': doneValue,
    if (failValue != null) 'failValue': failValue,
    if (resultPath != null) 'resultPath': resultPath,
    if (resultImagePath != null) 'resultImagePath': resultImagePath,
    if (resultFilePath != null) 'resultFilePath': resultFilePath,
    'intervalSeconds': intervalSeconds,
  };
}

class FormInputConfig {
  final String label;
  final String type;
  final double width;
  final double height;
  final String? defaultValue;
  final List<String>? options;

  FormInputConfig({
    required this.label,
    required this.type,
    this.width = 300,
    this.height = 60,
    this.defaultValue,
    this.options,
  });

  factory FormInputConfig.fromJson(Map<String, dynamic> json) {
    return FormInputConfig(
      label: json['label'] as String,
      type: json['type'] as String,
      width: (json['width'] as num?)?.toDouble() ?? 300,
      height: (json['height'] as num?)?.toDouble() ?? 60,
      defaultValue: json['defaultValue'] as String?,
      options: (json['options'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'type': type,
    'width': width,
    'height': height,
    if (defaultValue != null) 'defaultValue': defaultValue,
    if (options != null) 'options': options,
  };

  FormInput toFormInput() {
    final inputType = switch (type) {
      'text' => FormInputType.text,
      'textArea' => FormInputType.textArea,
      'range' => FormInputType.range,
      'int' => FormInputType.int,
      'double' => FormInputType.double,
      'dropdown' => FormInputType.dropdown,
      _ => FormInputType.text,
    };

    return FormInput(
      label: label,
      type: inputType,
      width: width,
      height: height,
      defaultValue: defaultValue,
      options: options,
    );
  }
}

class InputConfig {
  final String label;
  final Color color;

  InputConfig({required this.label, required this.color});

  factory InputConfig.fromJson(Map<String, dynamic> json) {
    return InputConfig(label: json['label'] as String, color: Color(int.parse(json['color'].toString())));
  }

  Map<String, dynamic> toJson() => {'label': label, 'color': '0x${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}'};
}

class OutputConfig {
  final String label;
  final Color color;

  OutputConfig({required this.label, required this.color});

  factory OutputConfig.fromJson(Map<String, dynamic> json) {
    return OutputConfig(label: json['label'] as String, color: Color(int.parse(json['color'].toString())));
  }

  Map<String, dynamic> toJson() => {'label': label, 'color': '0x${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}'};
}

class NodeConfig {
  final String typeName;
  final String displayName;
  final String? description;
  final String? icon;
  final int? color;
  final List<InputConfig> inputs;
  final List<OutputConfig> outputs;
  final List<FormInputConfig> formInputs;
  final RequestConfig? request;
  final ResponseConfig? response;
  final PollingConfig? polling;

  NodeConfig({
    required this.typeName,
    required this.displayName,
    this.description,
    this.icon,
    this.color,
    this.inputs = const [],
    this.outputs = const [],
    this.formInputs = const [],
    this.request,
    this.response,
    this.polling,
  });

  factory NodeConfig.fromJson(Map<String, dynamic> json) {
    return NodeConfig(
      typeName: json['typeName'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] != null ? int.parse(json['color'].toString()) : null,
      inputs: (json['inputs'] as List<dynamic>?)?.map((e) => InputConfig.fromJson(e)).toList() ?? [],
      outputs: (json['outputs'] as List<dynamic>?)?.map((e) => OutputConfig.fromJson(e)).toList() ?? [],
      formInputs: (json['formInputs'] as List<dynamic>?)?.map((e) => FormInputConfig.fromJson(e)).toList() ?? [],
      request: json['request'] != null ? RequestConfig.fromJson(json['request']) : null,
      response: json['response'] != null ? ResponseConfig.fromJson(json['response']) : null,
      polling: json['polling'] != null ? PollingConfig.fromJson(json['polling']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'typeName': typeName,
    'displayName': displayName,
    if (description != null) 'description': description,
    if (icon != null) 'icon': icon,
    if (color != null) 'color': '0x${color!.toRadixString(16).padLeft(8, '0').toUpperCase()}',
    if (inputs.isNotEmpty) 'inputs': inputs.map((i) => i.toJson()).toList(),
    if (outputs.isNotEmpty) 'outputs': outputs.map((o) => o.toJson()).toList(),
    if (formInputs.isNotEmpty) 'formInputs': formInputs.map((f) => f.toJson()).toList(),
    if (request != null) 'request': request!.toJson(),
    if (response != null) 'response': response!.toJson(),
    if (polling != null) 'polling': polling!.toJson(),
  };
}

// --- DynamicNode ---

class DynamicNode extends FormNode {
  final NodeConfig config;

  @override
  String get typeName => config.typeName;

  DynamicNode({required this.config, super.offset, super.uuid, super.key, List<FormInput>? customFormInputs})
    : super(
        label: config.displayName,
        color: config.color != null ? Color(config.color!) : Colors.orangeAccent,
        size: const Size(400, 400),
        inputs: config.inputs.map((i) => Input(label: i.label, color: i.color)).toList(),
        outputs: config.outputs.map((o) => Output(label: o.label, color: o.color)).toList(),
        formInputs: customFormInputs ?? config.formInputs.map((f) => f.toFormInput()).toList(),
      );

  factory DynamicNode.fromJson(Map<String, dynamic> json, NodeConfig config) {
    final data = Node.fromJson(json);
    final formInputs = (json['formInputs'] as List<dynamic>?)?.map((i) => FormInput.fromJson(i)).toList();

    return DynamicNode(
      config: config,
      offset: data.offset,
      uuid: json['uuid'] as String?,
      customFormInputs: formInputs,
    );
  }

  /// Build the template context from form values and upstream inputs.
  Map<String, dynamic> _buildContext({List<PromptResponse>? upstreamInputs, String? jobId}) {
    // form.Label -> value
    final formMap = <String, dynamic>{};
    for (final input in formInputs) {
      formMap[input.label] = input.controller.text.isNotEmpty ? input.controller.text : input.defaultValue ?? '';
    }

    // input.0 -> PromptResponse (with base64 accessor)
    final inputMap = <String, dynamic>{};
    if (upstreamInputs != null) {
      for (var i = 0; i < upstreamInputs.length; i++) {
        final resp = upstreamInputs[i];
        inputMap[i.toString()] = {
          'base64': resp.images.isNotEmpty ? base64Encode(resp.images.first) : '',
          'bytes': resp.images.isNotEmpty ? resp.images.first : Uint8List(0),
        };
      }
    }

    return {'form': formMap, 'input': inputMap, if (jobId != null) 'jobId': jobId};
  }

  @override
  Future<PromptResponse> run(BuildContext context, ExecutionContext cache) async {
    NodeEditorController? editor = NodeControls.of(context);
    AppState provider = Inherited.of(context)!;

    if (formKey.currentState != null && formKey.currentState!.validate()) {
      // Gather upstream inputs
      final upstreamInputs = <PromptResponse>[];
      for (var i = 0; i < config.inputs.length; i++) {
        final incoming = editor?.incomingNodes(this, i) ?? [];
        for (final node in incoming) {
          final result = await node.execute(context, cache);
          if (result is PromptResponse) {
            upstreamInputs.add(result);
          }
        }
      }

      if (config.polling != null) {
        return _executePolling(provider, upstreamInputs);
      } else {
        return _executeSingleRequest(provider, upstreamInputs);
      }
    }

    throw Exception('${config.displayName}: form validation failed');
  }

  Future<PromptResponse> _executeSingleRequest(AppState provider, List<PromptResponse> upstreamInputs) async {
    final ctx = _buildContext(upstreamInputs: upstreamInputs);
    final reqConfig = config.request;
    if (reqConfig == null) {
      throw Exception('${config.displayName}: no request config defined');
    }

    final url = resolveTemplates(reqConfig.url, ctx) as String;
    final method = reqConfig.method.toUpperCase();
    final headers = (resolveTemplates(reqConfig.headers, ctx) as Map).map(
      (k, v) => MapEntry(k.toString(), v.toString()),
    );
    final body = reqConfig.body != null ? resolveTemplates(reqConfig.body, ctx) : null;

    final client = http.Client();
    try {
      http.Response response;
      final uri = Uri.parse(url);
      if (method == 'GET') {
        response = await client.get(uri, headers: headers);
      } else {
        response = await client.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
      }

      final json = jsonDecode(response.body);
      return _parseResponse(json, client);
    } catch (e) {
      client.close();
      rethrow;
    }
  }

  Future<PromptResponse> _parseResponse(dynamic json, http.Client client) async {
    final respConfig = config.response;
    if (respConfig == null) {
      client.close();
      throw Exception('${config.displayName}: no response config defined');
    }

    try {
      final images = <Uint8List>[];
      String? info;

      if (respConfig.images != null) {
        final imageData = resolveJsonPath(json, respConfig.images!);
        final encoding = respConfig.imageEncoding ?? 'base64';

        if (imageData is List) {
          for (final item in imageData) {
            if (encoding == 'base64') {
              images.add(base64Decode(item.toString()));
            } else {
              // URL — download
              final resp = await client.get(Uri.parse(item.toString()));
              images.add(Uint8List.fromList(resp.bodyBytes));
            }
          }
        } else if (imageData is String) {
          if (encoding == 'base64') {
            images.add(base64Decode(imageData));
          } else {
            final resp = await client.get(Uri.parse(imageData));
            images.add(Uint8List.fromList(resp.bodyBytes));
          }
        }
      }

      if (respConfig.info != null) {
        final infoData = resolveJsonPath(json, respConfig.info!);
        info = infoData?.toString();
      }

      return PromptResponse(images: images, info: info);
    } finally {
      client.close();
    }
  }

  Future<PromptResponse> _executePolling(AppState provider, List<PromptResponse> upstreamInputs) async {
    final polling = config.polling!;
    final ctx = _buildContext(upstreamInputs: upstreamInputs);

    // Resolve submit URL and body
    final submitUrl = resolveTemplates(polling.submitUrl, ctx) as String;
    final submitBody = polling.submitBody != null ? resolveTemplates(polling.submitBody, ctx) : null;

    // Pass upstream image for the queue thumbnail
    final thumbnailImage = upstreamInputs.isNotEmpty && upstreamInputs.first.images.isNotEmpty
        ? upstreamInputs.first.images.first
        : null;

    provider.enqueueRequest(() async {
      final client = http.Client();
      try {
        // Submit job
        final submitResp = await client.post(
          Uri.parse(submitUrl),
          headers: {'Content-Type': 'application/json'},
          body: submitBody != null ? jsonEncode(submitBody) : null,
        );
        final submitJson = jsonDecode(submitResp.body);
        final jobId = resolveJsonPath(submitJson, polling.jobIdPath)?.toString();
        if (jobId == null) throw Exception('${config.displayName}: could not extract jobId');

        // Poll loop
        while (true) {
          await Future.delayed(Duration(seconds: polling.intervalSeconds));

          final pollCtx = _buildContext(upstreamInputs: upstreamInputs, jobId: jobId);
          final queryUrl = resolveTemplates(polling.queryUrl, pollCtx) as String;
          final queryBody = polling.queryBody != null ? resolveTemplates(polling.queryBody, pollCtx) : null;

          final queryResp = await client.post(
            Uri.parse(queryUrl),
            headers: {'Content-Type': 'application/json'},
            body: queryBody != null ? jsonEncode(queryBody) : null,
          );
          final queryJson = jsonDecode(queryResp.body);
          final status = resolveJsonPath(queryJson, polling.statusPath)?.toString();

          if (status == polling.doneValue) {
            // Extract results
            final images = <Uint8List>[];
            if (polling.resultPath != null) {
              final resultData = resolveJsonPath(queryJson, polling.resultPath!);

              if (resultData is List && polling.resultImagePath != null) {
                // Download preview images
                final previewUrls = resolveJsonPath(resultData, polling.resultImagePath!);
                if (previewUrls is List) {
                  for (final url in previewUrls) {
                    if (url != null && url.toString().isNotEmpty) {
                      final resp = await client.get(Uri.parse(url.toString()));
                      images.add(Uint8List.fromList(resp.bodyBytes));
                      break; // Just the first preview
                    }
                  }
                }

                // Download result files
                if (polling.resultFilePath != null) {
                  final fileUrls = resolveJsonPath(resultData, polling.resultFilePath!);
                  if (fileUrls is List) {
                    for (final url in fileUrls) {
                      if (url != null && url.toString().isNotEmpty) {
                        final resp = await client.get(Uri.parse(url.toString()));
                        images.add(Uint8List.fromList(resp.bodyBytes));
                      }
                    }
                  }
                }
              }
            }

            if (images.isEmpty && thumbnailImage != null) {
              images.add(thumbnailImage);
            }

            return PromptResponse(images: images);
          } else if (polling.failValue != null && status == polling.failValue) {
            throw Exception('${config.displayName}: job failed (status: $status)');
          }
        }
      } finally {
        client.close();
      }
    }, image: thumbnailImage);

    // Return upstream image immediately (non-blocking)
    if (thumbnailImage != null) {
      return PromptResponse(images: [thumbnailImage]);
    }
    return PromptResponse(images: []);
  }
}
