import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'scan_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.document_scanner_outlined,
                size: 96,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                'Lucid',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Read food labels with confidence',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ScanScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Scan a Label'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                child: const Text('How Lucid works'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
