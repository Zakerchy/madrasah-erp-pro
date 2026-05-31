// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

import 'pwa_runtime_service.dart';

class _WebPwaRuntimeService implements PwaRuntimeService {
  final ValueNotifier<bool> _installAvailable = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _standaloneMode = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _onlineStatus = ValueNotifier<bool>(true);

  html.BeforeInstallPromptEvent? _deferredPrompt;
  StreamSubscription<html.Event>? _displayModeSub;
  StreamSubscription<html.Event>? _onlineSub;
  StreamSubscription<html.Event>? _offlineSub;
  StreamSubscription<html.Event>? _beforeInstallSub;
  StreamSubscription<html.Event>? _appInstalledSub;
  bool _initialized = false;

  @override
  ValueListenable<bool> get installAvailable => _installAvailable;

  @override
  ValueListenable<bool> get standaloneMode => _standaloneMode;

  @override
  ValueListenable<bool> get onlineStatus => _onlineStatus;

  @override
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _standaloneMode.value = _detectStandaloneMode();
    _onlineStatus.value = html.window.navigator.onLine ?? true;

    final media = html.window.matchMedia('(display-mode: standalone)');
    _displayModeSub = media.onChange.listen((_) {
      _standaloneMode.value = _detectStandaloneMode();
    });

    _onlineSub = html.window.onOnline.listen((_) {
      _onlineStatus.value = true;
    });
    _offlineSub = html.window.onOffline.listen((_) {
      _onlineStatus.value = false;
    });

    _beforeInstallSub = html.window.on['beforeinstallprompt'].listen((event) {
      if (event is html.BeforeInstallPromptEvent) {
        event.preventDefault();
        _deferredPrompt = event;
        _installAvailable.value = true;
      }
    });

    _appInstalledSub = html.window.on['appinstalled'].listen((_) {
      _deferredPrompt = null;
      _installAvailable.value = false;
      _standaloneMode.value = true;
    });
  }

  @override
  Future<bool> promptInstall() async {
    final prompt = _deferredPrompt;
    if (prompt == null) return false;

    await prompt.prompt();
    try {
      await prompt.userChoice;
    } catch (_) {
      // Some browsers may not resolve userChoice reliably.
    }
    _deferredPrompt = null;
    _installAvailable.value = false;
    _standaloneMode.value = _detectStandaloneMode();
    return true;
  }

  bool _detectStandaloneMode() {
    final mediaStandalone =
        html.window.matchMedia('(display-mode: standalone)').matches;
    final nav = html.window.navigator;
    final iosStandalone =
        (nav as dynamic).standalone == true; // iOS Safari specific.
    return mediaStandalone || iosStandalone;
  }

  bool _isIosSafari() {
    final ua = html.window.navigator.userAgent.toLowerCase();
    final isIos =
        ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');
    final isSafari =
        ua.contains('safari') && !ua.contains('crios') && !ua.contains('fxios');
    return isIos && isSafari;
  }

  @override
  String installHelpMessage({required bool isEnglish}) {
    if (_isIosSafari()) {
      return isEnglish
          ? 'For full-screen mode on iPhone/iPad: Share -> Add to Home Screen.'
          : 'iPhone/iPad full-screen mode পেতে: Share -> Add to Home Screen দিন।';
    }
    return isEnglish
        ? 'Open this app in Chrome/Edge and use Install App for full-screen mode.'
        : 'Chrome/Edge থেকে অ্যাপটি খুলে Install App দিলে full-screen mode পাবেন।';
  }

  @override
  void dispose() {
    _displayModeSub?.cancel();
    _onlineSub?.cancel();
    _offlineSub?.cancel();
    _beforeInstallSub?.cancel();
    _appInstalledSub?.cancel();
  }
}

PwaRuntimeService createPwaRuntimeService() => _WebPwaRuntimeService();
