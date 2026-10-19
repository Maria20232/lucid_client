import 'package:flutter/material.dart';

import '../models/ingredient.dart';
import '../services/api_service.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _url = TextEditingController();
  final _search = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _initialized = false;
  bool _saving = false;
  bool _searching = false;
  bool _testing = false;
  String _language = 'eng';
  String? _connection;
  List<Ingredient>? _results;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final app = AppScope.of(context);
      _url.text = app.baseUrl;
      _language = app.language;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _url.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    final app = AppScope.of(context);
    setState(() => _saving = true);
    try {
      await app.configure(_url.text, _language);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Settings saved.')));
      }
    } on Object catch (error) {
      if (mounted) {
        showError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _test() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _testing = true;
      _connection = null;
    });
    try {
      final health = await ApiService(baseUrl: _url.text).healthCheck();
      if (mounted) {
        setState(
          () => _connection =
              'Connected to backend ${health.version}. '
              '${health.kbSize} records. ${health.ocrReady ? 'Configured OCR is ready.' : 'OCR is unavailable; check the server installation.'}',
        );
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _connection = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _testing = false);
      }
    }
  }

  Future<void> _find() async {
    final app = AppScope.of(context);
    if (_search.text.trim().length < 2) {
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await app.api.searchIngredients(_search.text.trim());
      if (mounted) {
        setState(() => _results = results);
      }
    } on Object catch (error) {
      if (mounted) {
        showError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _toggle(Ingredient ingredient) async {
    final app = AppScope.of(context);
    setState(() => _saving = true);
    try {
      await app.toggleHighlight(ingredient);
    } on Object catch (error) {
      if (mounted) {
        showError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings & highlights')),
      body: pageList([
        Text(
          'Backend connection',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Form(
          key: _form,
          child: TextFormField(
            controller: _url,
            enabled: !_saving && !_testing,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Server URL',
              hintText: 'http://192.168.1.10:8000',
            ),
            validator: (value) {
              try {
                ApiService.validateBaseUrl(value ?? '');
                return null;
              } on FormatException catch (error) {
                return error.message;
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Chrome on your PC: localhost:8000\nAndroid emulator: 10.0.2.2:8000\nPhysical phone: your PC’s LAN IP, on the same Wi-Fi',
          style: TextStyle(color: AppColors.textSecondary, height: 1.6),
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<String>(
          initialValue: _language,
          decoration: const InputDecoration(labelText: 'OCR language'),
          items: const [
            DropdownMenuItem(value: 'eng', child: Text('English')),
            DropdownMenuItem(value: 'eng+msa', child: Text('English + Malay')),
          ],
          onChanged: _saving
              ? null
              : (value) => setState(() => _language = value ?? 'eng'),
        ),
        const SizedBox(height: 10),
        const Text(
          'The selected Tesseract language models must be installed on the backend.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton(
              onPressed: _saving || _testing ? null : _save,
              child: const Text('Save settings'),
            ),
            OutlinedButton(
              onPressed: _saving || _testing ? null : _test,
              child: Text(_testing ? 'Checking…' : 'Test connection'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_connection != null) NoticeBox(_connection!),
        const SizedBox(height: 20),
        Text(
          'Personal ingredient highlights',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const NoticeBox(
          'Choose ingredients you want Lucid to highlight. These are exact-ID preferences, stored on this device. They are not an allergen or dietary-compliance assessment.',
        ),
        for (final ingredient in app.highlights)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(ingredient.name),
            subtitle: Text(ingredient.id),
            trailing: IconButton(
              tooltip: 'Remove highlight',
              onPressed: _saving ? null : () => _toggle(ingredient),
              icon: const Icon(Icons.bookmark_remove_outlined),
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          enabled: !_searching,
          decoration: const InputDecoration(
            labelText: 'Search ingredients to highlight',
          ),
          onSubmitted: (_) {
            if (!_searching) {
              _find();
            }
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _searching ? null : _find,
          icon: const Icon(Icons.search),
          label: Text(_searching ? 'Searching…' : 'Search saved server'),
        ),
        if (_results != null && _results!.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No ingredients found. Try a name or E-number.'),
          ),
        for (final ingredient in _results ?? <Ingredient>[])
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(ingredient.name),
            subtitle: Text(ingredient.id),
            trailing: IconButton(
              tooltip: app.isHighlighted(ingredient.id)
                  ? 'Remove highlight'
                  : 'Add highlight',
              onPressed: _saving ? null : () => _toggle(ingredient),
              icon: Icon(
                app.isHighlighted(ingredient.id)
                    ? Icons.bookmark
                    : Icons.bookmark_border,
              ),
            ),
          ),
        const SizedBox(height: 20),
        const Text(
          'Saved labels and highlights stay in this app’s local preferences. They are not encrypted or backed up by Lucid. Photos are kept only for the active review flow.',
          style: TextStyle(color: AppColors.textMuted, height: 1.5),
        ),
      ]),
    );
  }
}
