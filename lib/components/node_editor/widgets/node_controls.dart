import 'package:flutter/material.dart';
import '../controller/node_editor_controller.dart';

/// InheritedWidget that provides NodeEditorController to descendants
class NodeControls extends InheritedNotifier<NodeEditorController> {
  const NodeControls({
    required super.child,
    required super.notifier,
    super.key,
  });

  static NodeEditorController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NodeControls>()?.notifier;

  @override
  bool updateShouldNotify(InheritedNotifier<NodeEditorController> oldWidget) => true;
}
