import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'products_screen.dart';
import 'review_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final bool recoverLostImages;
  const WelcomeScreen({super.key, this.recoverLostImages = true});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? _healthUrl;
  Future<BackendHealth>? _health;

  @override
  void initState() {
    super.initState();
    if (widget.recoverLostImages &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _recoverPhoto());
    }
  }

  Future<void> _recoverPhoto() async {
    try {
      final response = await ImagePicker().retrieveLostData();
      if (!mounted || response.isEmpty) {
        return;
      }
      final files = response.files;
      if (files != null && files.isNotEmpty) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ScanScreen(recoveredFile: files.first),
          ),
        );
      } else if (response.exception != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The interrupted photo selection could not be recovered. Please choose it again.',
            ),
          ),
        );
      }
    } on Object {
      // A failed recovery must not prevent manual entry or a fresh scan.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    if (_healthUrl != app.baseUrl) {
      _healthUrl = app.baseUrl;
      _health = app.api.healthCheck();
    }
  }

  void _open(Widget screen) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lucid'),
        actions: [
          IconButton(
            tooltip: 'Settings and highlights',
            onPressed: () => _open(const SettingsScreen()),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: pageList([
        const SizedBox(height: 24),
        const Icon(
          Icons.document_scanner_outlined,
          size: 76,
          color: AppColors.primary,
        ),
        const SizedBox(height: 22),
        Text(
          'Make sense of the label.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        const Text(
          'Scan ingredients, review the text, and explore the source information. Save products to compare what was recognized.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 17,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: () => _open(const ScanScreen()),
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Scan a label'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _open(const ReviewScreen()),
          icon: const Icon(Icons.edit_note),
          label: const Text('Enter ingredients'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _open(const ProductsScreen()),
          icon: const Icon(Icons.compare_arrows),
          label: Text('Saved products & compare (${app.products.length})'),
        ),
        const SizedBox(height: 24),
        if (app.storageWarning != null)
          NoticeBox(app.storageWarning!, warning: true),
        FutureBuilder<BackendHealth>(
          future: _health,
          builder: (context, snapshot) {
            final health = snapshot.data;
            final String message;
            if (snapshot.connectionState != ConnectionState.done) {
              message = 'Checking the backend…';
            } else if (snapshot.hasError) {
              message =
                  'Backend is not reachable. Check the server URL in Settings.';
            } else if (health?.ocrReady == true) {
              message =
                  'Backend connected · ${health!.kbSize} knowledge records · OCR ready';
            } else {
              message = 'Backend connected. OCR is unavailable; you can try entering ingredients manually.';
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NoticeBox(
                  message,
                  warning:
                      snapshot.hasError || (health != null && !health.ocrReady),
                ),
                TextButton(
                  onPressed: snapshot.connectionState == ConnectionState.waiting
                      ? null
                      : () {
                          setState(() => _health = app.api.healthCheck());
                        },
                  child: const Text('Check connection again'),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('How Lucid works'),
              content: const SingleChildScrollView(
                child: Text(
                  '1. Choose or take a label photo.\n\n2. Review and correct the OCR text.\n\n3. Check ingredient matches and source information.\n\n4. Highlight ingredients you want to notice.\n\n5. Save two products and compare recognized ingredients.\n\nExplanations currently come from taxonomy records. Unknown text remains unresolved.',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it'),
                ),
              ],
            ),
          ),
          child: const Text('How Lucid works'),
        ),
      ]),
    );
  }
}
