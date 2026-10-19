import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'services/local_store.dart';
import 'state/app_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController(store: PreferencesStore());
  await controller.load();
  runApp(LucidApp(controller: controller));
}

class LucidApp extends StatelessWidget {
  final AppController controller;
  final bool recoverLostImages;
  const LucidApp({
    super.key,
    required this.controller,
    this.recoverLostImages = true,
  });

  @override
  Widget build(BuildContext context) => AppScope(
    controller: controller,
    child: MaterialApp(
      title: 'Lucid',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: WelcomeScreen(recoverLostImages: recoverLostImages),
    ),
  );
}
