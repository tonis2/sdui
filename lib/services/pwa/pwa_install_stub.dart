import 'dart:async';

/// Stub implementation of PwaInstallService for non-web platforms
class PwaInstallService {
  static final PwaInstallService _instance = PwaInstallService._internal();
  factory PwaInstallService() => _instance;
  PwaInstallService._internal();

  final _installAvailableController = StreamController<bool>.broadcast();

  Stream<bool> get onInstallAvailable => _installAvailableController.stream;
  bool get isInstallAvailable => false;

  void init() {}
  Future<bool> promptInstall() async => false;
  void dispose() => _installAvailableController.close();
}
