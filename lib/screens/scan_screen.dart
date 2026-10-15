import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'results_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isProcessing = false;

  Future<void> _takePhoto() async {
    setState(() => _isProcessing = true);

    // Fake processing delay — replace with real OCR call later
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isProcessing = false);

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ResultsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan a Label'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Camera placeholder
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: _isProcessing
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 24),
                              Text(
                                'Reading the label...',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 72,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Camera preview\n(will show here)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isProcessing ? null : _takePhoto,
                icon: const Icon(Icons.camera),
                label: Text(_isProcessing ? 'Processing...' : 'Take Photo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}