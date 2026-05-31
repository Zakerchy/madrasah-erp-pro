import 'package:flutter/foundation.dart';

import 'pwa_runtime_service_stub.dart'
    if (dart.library.html) 'pwa_runtime_service_web.dart';

abstract class PwaRuntimeService {
  ValueListenable<bool> get installAvailable;
  ValueListenable<bool> get standaloneMode;
  ValueListenable<bool> get onlineStatus;

  Future<void> init();
  Future<bool> promptInstall();
  String installHelpMessage({required bool isEnglish});
  void dispose();
}

final PwaRuntimeService pwaRuntimeService = createPwaRuntimeService();
