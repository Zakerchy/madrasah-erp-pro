import 'package:flutter/material.dart';
import 'app_drawer.dart';

class BaseScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const BaseScaffold({super.key, required this.title, required this.body, this.actions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: const AppDrawer(),
      body: body,
    );
  }
}
