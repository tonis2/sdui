import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// JS interop for BeforeInstallPromptEvent
extension type BeforeInstallPromptEvent(JSObject _) implements web.Event {
  external JSPromise<InstallPromptResult> get userChoice;
  external void prompt();
}

/// JS interop for install prompt result
extension type InstallPromptResult(JSObject _) implements JSObject {
  external String get outcome;
}

/// Extension to access deferredPwaPrompt on window
extension WindowPwaPrompt on web.Window {
  external JSObject? get deferredPwaPrompt;
  external set deferredPwaPrompt(JSObject? value);
}

/// Web implementation of PwaInstallService
class PwaInstallService {
  static final PwaInstallService _instance = PwaInstallService._internal();
  factory PwaInstallService() => _instance;
  PwaInstallService._internal();

  BeforeInstallPromptEvent? _deferredPrompt;
  final _installAvailableController = StreamController<bool>.broadcast();

  Stream<bool> get onInstallAvailable => _installAvailableController.stream;
  bool get isInstallAvailable => _deferredPrompt != null;

  void init() {
    // Check if the prompt was already captured in JavaScript before Flutter loaded
    final preCapture = web.window.deferredPwaPrompt;
    if (preCapture != null) {
      _deferredPrompt = BeforeInstallPromptEvent(preCapture);
      _installAvailableController.add(true);
      // Clear it from window so we don't reuse it
      web.window.deferredPwaPrompt = null;
    }

    web.window.addEventListener(
      'beforeinstallprompt',
      ((web.Event event) {
        event.preventDefault();
        _deferredPrompt = event as BeforeInstallPromptEvent;
        _installAvailableController.add(true);
      }).toJS,
    );

    web.window.addEventListener(
      'appinstalled',
      ((web.Event event) {
        _deferredPrompt = null;
        _installAvailableController.add(false);
      }).toJS,
    );
  }

  Future<bool> promptInstall() async {
    if (_deferredPrompt == null) return false;

    _deferredPrompt!.prompt();
    final result = await _deferredPrompt!.userChoice.toDart;

    _deferredPrompt = null;
    _installAvailableController.add(false);

    return result.outcome == 'accepted';
  }

  void dispose() {
    _installAvailableController.close();
  }
}
