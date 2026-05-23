import 'package:flutter/material.dart';
import 'app_drawer.dart';
import '../services/local_store_service.dart';
import '../services/sync_service.dart';

class BaseScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const BaseScaffold({super.key, required this.title, required this.body, this.actions});

  @override
  Widget build(BuildContext context) {
    final mergedActions = <Widget>[
      ...?actions,
      ValueListenableBuilder<int>(
        valueListenable: LocalStoreService.pendingCount,
        builder: (_, pending, __) {
          return IconButton(
            tooltip: pending > 0 ? 'Sync pending ($pending)' : 'Sync',
            onPressed: () async {
              final res = await SyncService.syncPending();
              if (!context.mounted) return;
              final authRequired = res['auth_required'] == true;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    authRequired
                        ? 'Sync প্রয়োজন: আগে একই Gmail দিয়ে Google Sync verify করুন'
                        : 'Synced: ${res['synced'] ?? 0}, Pending: ${res['remaining'] ?? 0}',
                  ),
                ),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.sync),
                if (pending > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pending.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: mergedActions),
      drawer: const AppDrawer(),
      body: body,
    );
  }
}
