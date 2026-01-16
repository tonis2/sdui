/// Node Editor Component Library
///
/// A visual node-based editor for creating flow-based graphs.
///
/// Main exports:
/// - [NodeCanvas] - The main canvas widget
/// - [NodeEditorController] - Controller for managing editor state
/// - [Node] - Base class for custom node types
/// - [Input], [Output] - Connector types for nodes
/// - [Connection] - Represents connections between nodes
library;

// Models

export 'models/index.dart';

// Controller
export 'controller/node_editor_controller.dart';

// Widgets
export 'widgets/node_canvas.dart';
export 'widgets/node_controls.dart';
export 'widgets/node_base_widget.dart';
export 'widgets/connector_row.dart';
export 'widgets/context_menus.dart';

// Painters
export 'painters/line_painter.dart';

// Utils
export 'utils/node_layout.dart';
