# NodeEditor JSON Serialization Plan

## Current State Analysis

### What's Already Implemented

1. **NodeEditorController** (`lib/components/node_editor/canvas.dart`)
   - `toJson()` method - Serializes nodes and connections
   - `fromJson()` method - Deserializes nodes and connections
   - `registerNodeType()` method - Registers node factories for deserialization
   - `_nodeFactories` map - Stores registered node types

2. **Node** (base class in `lib/components/node_editor/canvas.dart`)
   - `toJson()` method - Serializes common properties
   - Static `fromJson()` helper - Returns `NodeData` with common properties

3. **FormNode** (`lib/components/node_editor/nodes/form.dart`)
   - `fromJson()` factory - Creates FormNode from JSON
   - `toJson()` method - Includes formInputs

4. **FormInput** (`lib/components/node_editor/nodes/form.dart`)
   - `fromJson()` factory
   - `toJson()` method

5. **Input** and **Output** (`lib/components/node_editor/canvas.dart`)
   - Both have `fromJson()` factory and `toJson()` method

6. **Connection** (`lib/components/node_editor/canvas.dart`)
   - `toJson()` method
   - Static `fromJson()` method

### Issues Found

#### 1. UUID Preservation Problem
The `Node.uuid` field is generated with `Uuid().v4()` on construction:
```dart
final String uuid = Uuid().v4();
```

This breaks deserialization because:
- When loading from JSON, a new UUID is generated
- Connections reference nodes by UUID, so they become invalid
- The original UUID from JSON is lost

#### 2. Missing Serialization Methods

| Node Type | fromJson() | toJson() | Notes |
|-----------|-----------|----------|-------|
| ImageNode | ❌ Missing | ❌ Missing | Has `image` (ui.Image) and `data` (Uint8List) fields |
| PromptNode | ❌ Missing | ✅ Inherited | Extends FormNode |
| KoboldNode | ❌ Missing | ✅ Inherited | Extends FormNode |

#### 3. FormNode.fromJson() UUID Issue
The `FormNode.fromJson()` method doesn't restore the UUID from JSON:
```dart
factory FormNode.fromJson(Map<String, dynamic> json) {
  final data = Node.fromJson(json);
  // ... creates new FormNode with new UUID
}
```

#### 4. Missing Node Type Registration
The `NodeEditorController.registerNodeType()` method exists but node types are never registered in the `NodeEditor` widget.

#### 5. Missing Save/Load UI
There's no UI or mechanism to trigger save/load operations in the `NodeEditor` widget.

---

## Proposed Solution

### Step 1: Fix Node Class UUID Preservation

Change the `Node` class to accept an optional UUID parameter:

```dart
abstract class Node extends StatelessWidget {
  final String? id;
  final String label;
  final List<Input> inputs;
  final List<Output> outputs;
  final Color color;
  final String uuid;
  final Size size;
  Offset offset;

  Node({
    this.id,
    required this.label,
    required this.inputs,
    required this.outputs,
    this.offset = const Offset(0, 0),
    this.color = const Color.fromRGBO(128, 186, 215, 0.5),
    this.size = const Size(100, 100),
    String? uuid,  // Optional UUID parameter
    super.key,
  }) : uuid = uuid ?? Uuid().v4();  // Use provided UUID or generate new one
```

### Step 2: Add Serialization to ImageNode

Add `toJson()` method:
```dart
@override
Map<String, dynamic> toJson() {
  final json = super.toJson();
  json["imageData"] = data != null ? base64Encode(data!) : null;
  return json;
}
```

Add `fromJson()` factory:
```dart
factory ImageNode.fromJson(Map<String, dynamic> json) {
  final data = Node.fromJson(json);
  final imageData = json["imageData"] as String?;
  
  Uint8List? imageBytes;
  if (imageData != null) {
    imageBytes = base64Decode(imageData);
  }
  
  return ImageNode(
    label: data.label,
    offset: data.offset,
    size: data.size,
    color: data.color,
    inputs: data.inputs,
    outputs: data.outputs,
    uuid: json["uuid"],  // Preserve UUID
  )..data = imageBytes;
}
```

### Step 3: Add fromJson() to PromptNode

```dart
factory PromptNode.fromJson(Map<String, dynamic> json) {
  final data = Node.fromJson(json);
  final formInputs = (json["formInputs"] as List<dynamic>?)
      ?.map((i) => FormInput.fromJson(i)).toList() ?? [];

  return PromptNode(
    label: data.label,
    offset: data.offset,
    size: data.size,
    color: data.color,
    inputs: data.inputs,
    outputs: data.outputs,
    uuid: json["uuid"],  // Preserve UUID
    formInputs: formInputs,
  );
}
```

### Step 4: Add fromJson() to KoboldNode

```dart
factory KoboldNode.fromJson(Map<String, dynamic> json) {
  final data = Node.fromJson(json);
  final formInputs = (json["formInputs"] as List<dynamic>?)
      ?.map((i) => FormInput.fromJson(i)).toList() ?? [];

  return KoboldNode(
    label: data.label,
    offset: data.offset,
    size: data.size,
    color: data.color,
    inputs: data.inputs,
    outputs: data.outputs,
    uuid: json["uuid"],  // Preserve UUID
    formInputs: formInputs,
  );
}
```

### Step 5: Update FormNode.fromJson() to Preserve UUID

```dart
factory FormNode.fromJson(Map<String, dynamic> json) {
  final data = Node.fromJson(json);
  final formInputs = (json["formInputs"] as List<dynamic>?)
      ?.map((i) => FormInput.fromJson(i)).toList() ?? [];

  return FormNode(
    label: data.label,
    offset: data.offset,
    size: data.size,
    color: data.color,
    inputs: data.inputs,
    outputs: data.outputs,
    uuid: json["uuid"],  // Preserve UUID from JSON
    formInputs: formInputs,
  );
}
```

### Step 6: Create Node Type Registration Helper

Create a helper function or method in `NodeEditor` widget:

```dart
void _registerNodeTypes() {
  controller.registerNodeType("ImageNode", (json) => ImageNode.fromJson(json));
  controller.registerNodeType("PromptNode", (json) => PromptNode.fromJson(json));
  controller.registerNodeType("KoboldNode", (json) => KoboldNode.fromJson(json));
  controller.registerNodeType("FormNode", (json) => FormNode.fromJson(json));
}
```

Call this in `initState()`:
```dart
@override
void initState() {
  _registerNodeTypes();  // Register node types before loading
  // ... rest of initState
}
```

### Step 7: Add Save/Load Functionality

Add methods to `NodeEditor` widget:

```dart
Future<void> saveCanvas() async {
  final json = controller.toJson();
  final jsonString = jsonEncode(json);
  // Save to file or storage
}

Future<void> loadCanvas(String jsonString) async {
  final json = jsonDecode(jsonString);
  controller.fromJson(json);
}
```

Add UI buttons for save/load operations.

### Step 8: Image Data Handling Considerations

For `ImageNode`, note that:
- `ui.Image` cannot be directly serialized
- We serialize `Uint8List data` as base64
- On load, we need to reconstruct the `ui.Image` from bytes
- This should happen when the node is built or lazily

---

## Implementation Order

1. Fix `Node` class to accept optional UUID parameter
2. Update `FormNode.fromJson()` to preserve UUID
3. Add `toJson()` to `ImageNode`
4. Add `fromJson()` to `ImageNode`
5. Add `fromJson()` to `PromptNode`
6. Add `fromJson()` to `KoboldNode`
7. Add node type registration to `NodeEditor.initState()`
8. Add save/load methods to `NodeEditor`
9. Add UI buttons for save/load
10. Test the complete flow

---

## Files to Modify

1. `lib/components/node_editor/canvas.dart` - Node class UUID fix
2. `lib/components/node_editor/nodes/form.dart` - FormNode.fromJson() UUID fix
3. `lib/pages/node_editor/image.dart` - Add toJson() and fromJson()
4. `lib/pages/node_editor/form.dart` - Add fromJson() to PromptNode
5. `lib/pages/node_editor/kobold_node.dart` - Add fromJson() to KoboldNode
6. `lib/pages/node_editor/index.dart` - Add node registration and save/load

---

## Testing Checklist

- [ ] Save empty canvas
- [ ] Load empty canvas
- [ ] Save canvas with single ImageNode
- [ ] Load canvas with single ImageNode
- [ ] Save canvas with single PromptNode
- [ ] Load canvas with single PromptNode
- [ ] Save canvas with single KoboldNode
- [ ] Load canvas with single KoboldNode
- [ ] Save canvas with multiple nodes
- [ ] Load canvas with multiple nodes
- [ ] Save canvas with connections between nodes
- [ ] Load canvas with connections between nodes
- [ ] Verify UUIDs are preserved after load
- [ ] Verify connections work after load
- [ ] Verify form input values are preserved after load
- [ ] Verify image data is preserved after load
