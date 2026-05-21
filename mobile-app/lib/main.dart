import 'package:flutter/material.dart';

import 'core/app_shell.dart';
import 'shared/services/session_service.dart';
import 'shared/services/sync_orchestrator_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionService.bootstrap();
  await SyncOrchestratorService.start();
  runApp(const MadrasahErpLiteApp());
}
