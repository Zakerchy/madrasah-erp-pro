import 'package:flutter/material.dart';

import 'core/app_lang.dart';
import 'core/app_shell.dart';
import 'shared/services/pwa_runtime_service.dart';
import 'shared/services/session_service.dart';
import 'shared/services/sync_orchestrator_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLang.init();
  await SessionService.bootstrap();
  try {
    await pwaRuntimeService.init();
  } catch (_) {
    // Never block app boot because of optional web runtime hooks.
  }
  await SyncOrchestratorService.start();
  runApp(const MadrasahErpLiteApp());
}
