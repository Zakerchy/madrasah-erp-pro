import 'package:flutter/foundation.dart';

import 'pwa_runtime_service.dart';

class _StubPwaRuntimeService implements PwaRuntimeService {
  final ValueNotifier<bool> _installAvailable = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _standaloneMode = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _onlineStatus = ValueNotifier<bool>(true);

  @override
  ValueListenable<bool> get installAvailable => _installAvailable;

  @override
  ValueListenable<bool> get standaloneMode => _standaloneMode;

  @override
  ValueListenable<bool> get onlineStatus => _onlineStatus;

  @override
  Future<void> init() async {}

  @override
  Future<bool> promptInstall() async => false;

  @override
  String installHelpMessage({required bool isEnglish}) {
    return isEnglish
        ? 'Install prompt is available in supported browsers only.'
        : 'Install prompt কেবল supported browser-এ পাওয়া যায়।';
  }

  @override
  void dispose() {}
}

PwaRuntimeService createPwaRuntimeService() => _StubPwaRuntimeService();
