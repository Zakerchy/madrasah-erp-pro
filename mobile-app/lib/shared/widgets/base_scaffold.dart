import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../core/theme.dart';
import '../services/local_store_service.dart';
import '../services/sync_service.dart';
import 'app_drawer.dart';

/// Responsive application shell:
/// - Desktop (>= 960px): Sticky left sidebar + main content area.
/// - Mobile (< 960px): Standard AppBar + slide-out Drawer.
/// Also renders a subtle pending-sync banner whenever offline mutations are queued.
class BaseScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  static const double desktopBreakpoint = 960;

  const BaseScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  Future<void> _triggerSync(BuildContext context) async {
    final res = await SyncService.syncPending();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLang.t(
            'সিঙ্ক: ${res['synced'] ?? 0}, বাকি: ${res['remaining'] ?? 0}',
            'Synced: ${res['synced'] ?? 0}, Pending: ${res['remaining'] ?? 0}',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLang.isEnglish,
      builder: (context, _, __) {
        final isDesktop =
            MediaQuery.sizeOf(context).width >= desktopBreakpoint;
        final scheme = Theme.of(context).colorScheme;

        final mergedActions = <Widget>[
          ...?actions,
          ValueListenableBuilder<int>(
            valueListenable: LocalStoreService.pendingCount,
            builder: (_, pending, __) {
              return IconButton(
                tooltip: pending > 0
                    ? AppLang.t(
                        'সিঙ্ক বাকি ($pending)', 'Sync pending ($pending)')
                    : AppLang.t('সিঙ্ক', 'Sync'),
                onPressed: () => _triggerSync(context),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.sync),
                    if (pending > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            pending.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ];

        final bodyWithSyncBanner = Column(
          children: [
            ValueListenableBuilder<int>(
              valueListenable: LocalStoreService.pendingCount,
              builder: (_, pending, __) {
                if (pending <= 0) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppBrand.gold.withValues(alpha: 0.16),
                    border: Border(
                      bottom: BorderSide(
                        color: AppBrand.gold.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          size: 18, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLang.t(
                            '$pendingটি অফলাইন এন্ট্রি সিঙ্কের অপেক্ষায় আছে',
                            '$pending offline entries waiting to sync',
                          ),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _triggerSync(context),
                        child: Text(AppLang.t('এখন সিঙ্ক করুন', 'Sync now')),
                      ),
                    ],
                  ),
                );
              },
            ),
            Expanded(child: body),
          ],
        );

        final scaffold = Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: !isDesktop,
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: mergedActions,
          ),
          drawer: isDesktop ? null : const AppDrawer(),
          body: bodyWithSyncBanner,
          floatingActionButton: floatingActionButton,
        );

        if (!isDesktop) return scaffold;

        return Row(
          children: [
            Container(
              width: 268,
              decoration: BoxDecoration(
                color: Theme.of(context).drawerTheme.backgroundColor ??
                    scheme.surface,
                border: Border(
                  right: BorderSide(
                    color: AppBrand.gold.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: const Material(
                type: MaterialType.transparency,
                child: AppNavContent(isDrawer: false),
              ),
            ),
            Expanded(child: scaffold),
          ],
        );
      },
    );
  }
}
