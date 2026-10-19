import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'review_screen.dart';

class ScanScreen extends StatefulWidget {
  final XFile? recoveredFile;
  const ScanScreen({super.key, this.recoveredFile});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _picker = ImagePicker();
  Uint8List? _image;
  String _filename = 'label.jpg';
  bool _busy = false;
  String? _error;

  bool get _cameraSupported =>
      !kIsWeb &&
      [
        TargetPlatform.android,
        TargetPlatform.iOS,
      ].contains(defaultTargetPlatform);

  @override
  void initState() {
    super.initState();
    final file = widget.recoveredFile;
    if (file != null) {
      _readRecovered(file);
    }
  }

  Future<void> _readRecovered(XFile file) async {
    try {
      await _readFile(file);
    } on Object {
      if (mounted) {
        setState(
          () => _error = 'The recovered photo could not be opened. Please choose it again.',
        );
      }
    }
  }

  Future<void> _readFile(XFile file) async {
    final size = await file.length();
    if (size == 0 || size > ApiService.maxImageBytes) {
      throw const ApiException('Choose a nonempty image under 10 MiB.');
    }
    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }
    setState(() {
      _image = bytes;
      _filename = file.name;
      _error = null;
    });
  }

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 2600,
        maxHeight: 2600,
        imageQuality: 90,
        requestFullMetadata: false,
      );
      if (file != null) {
        await _readFile(file);
      }
    } on PlatformException {
      if (mounted) {
        setState(
          () => _error = 'Photo access is unavailable. Check the camera/photo permissions, or choose another image.',
        );
      }
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Could not open this image. Please choose another.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _scan() async {
    final bytes = _image;
    if (bytes == null) {
      return;
    }
    final controller = AppScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await controller.api.scanImage(
        bytes,
        filename: _filename,
        language: controller.language,
      );
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReviewScreen(initial: result, image: bytes),
        ),
      );
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'The scan could not be completed. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scan a label')),
    body: pageList([
      Text(
        'Start with the ingredients',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 10),
      const Text(
        'Fill the photo with the ingredient paragraph. Keep it in focus and avoid reflections.',
        style: TextStyle(color: AppColors.textSecondary, height: 1.5),
      ),
      const SizedBox(height: 24),
      ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: ColoredBox(
            color: AppColors.surface,
            child: _image == null
                ? const Center(
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 80,
                      color: AppColors.textMuted,
                    ),
                  )
                : Image.memory(
                    _image!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, error, stack) => const Center(
                      child: Text(
                        'Preview unavailable. Choose a JPEG or PNG image.',
                      ),
                    ),
                  ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          if (_cameraSupported)
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _pick(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Take photo'),
            ),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _pick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose photo'),
          ),
        ],
      ),
      const SizedBox(height: 20),
      if (_error != null) NoticeBox(_error!, warning: true),
      if (_busy)
        const Padding(
          padding: EdgeInsets.only(bottom: 18),
          child: LinearProgressIndicator(),
        ),
      FilledButton.icon(
        onPressed: _busy || _image == null ? null : _scan,
        icon: const Icon(Icons.document_scanner_outlined),
        label: Text(_busy ? 'Please wait…' : 'Read this label'),
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: _busy
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ReviewScreen()),
              ),
        child: const Text('Enter ingredients instead'),
      ),
      const SizedBox(height: 12),
      const Text(
        'The selected photo is sent to your configured Lucid backend for OCR.',
        style: TextStyle(color: AppColors.textMuted, height: 1.4),
      ),
    ]),
  );
}
