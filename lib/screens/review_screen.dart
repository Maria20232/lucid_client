import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/analysis_result.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'results_screen.dart';

class ReviewScreen extends StatefulWidget {
  final AnalysisResult? initial;
  final Uint8List? image;
  const ReviewScreen({super.key, this.initial, this.image});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final TextEditingController _text;
  AnalysisResult? _analysis;
  String? _lastAnalyzed;
  bool _busy = false;
  bool _reviewed = false;
  String? _error;

  bool get _current => _analysis != null && _lastAnalyzed == _text.text.trim();

  @override
  void initState() {
    super.initState();
    _analysis = widget.initial;
    _text = TextEditingController(text: widget.initial?.rawText ?? '');
    // A scan is intentionally not accepted as a reviewed analysis. Require
    // one /analyze call after the user has seen the text.
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final api = AppScope.of(context).api;
    final submitted = _text.text.trim();
    setState(() {
      _busy = true;
      _error = null;
      _reviewed = false;
    });
    try {
      final analysis = await api.analyzeText(submitted);
      if (!mounted) {
        return;
      }
      setState(() {
        _analysis = analysis;
        _lastAnalyzed = submitted;
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _useSuggestion(
    UnmatchedFragment fragment,
    IngredientSuggestion suggestion,
  ) {
    final start = _text.text.indexOf(fragment.text);
    if (start < 0) {
      return;
    }
    // Use the unambiguous taxonomy ID as a reviewed replacement. The label
    // and suggested name stay visible in the UI; /analyze verifies the edit.
    final next = _text.text.replaceRange(
      start,
      start + fragment.text.length,
      suggestion.ingredientId.replaceAll('_', ' '),
    );
    setState(() {
      _text.text = next;
      _text.selection = TextSelection.collapsed(offset: next.length);
      _reviewed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _analysis;
    return Scaffold(
      appBar: AppBar(title: const Text('Review the text')),
      body: pageList([
        const NoticeBox(
          'Compare the text with the printed label. Correct missing or misread words before checking ingredients.',
        ),
        if (widget.image != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: SizedBox(
              height: 220,
              child: InteractiveViewer(
                child: Image.memory(widget.image!, fit: BoxFit.contain),
              ),
            ),
          ),
        if (widget.initial?.ocrConfidence != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Original OCR score: ${widget.initial!.ocrConfidence!.toStringAsFixed(1)} / 100 · this is not accuracy',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
        if (_lastAnalyzed == null)
          for (final warning in widget.initial?.warnings ?? <String>[])
            NoticeBox(warning, warning: true),
        TextField(
          controller: _text,
          minLines: 6,
          maxLines: 14,
          maxLength: 10000,
          enabled: !_busy,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            labelText: 'Ingredient text',
            alignLabelWithHint: true,
            hintText: 'Ingredients: sugar, wheat flour, E322, salt…',
          ),
          onChanged: (_) => setState(() => _reviewed = false),
        ),
        if (_error != null) NoticeBox(_error!, warning: true),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(),
          ),
        FilledButton.icon(
          onPressed: _busy ? null : _check,
          icon: const Icon(Icons.spellcheck),
          label: const Text('Check ingredients'),
        ),
        const SizedBox(height: 24),
        if (analysis != null) ...[
          Text(
            _current
                ? '${analysis.ingredients.length} recognized ingredients'
                : 'Check the edited text to refresh these results',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (_current) ...[
            for (final warning in analysis.warnings)
              NoticeBox(warning, warning: true),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: analysis.ingredients
                  .map((i) => Chip(label: Text(i.name)))
                  .toList(),
            ),
            const SizedBox(height: 16),
            for (final fragment in analysis.unmatched)
              _UnmatchedCard(
                fragment: fragment,
                enabled: !_busy,
                onSelected: (suggestion) =>
                    _useSuggestion(fragment, suggestion),
              ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _reviewed,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _reviewed = value ?? false),
              title: const Text(
                'I reviewed the text and any unresolved fragments.',
              ),
              subtitle: const Text(
                'Unresolved text remains unresolved in saved products and comparisons.',
              ),
            ),
          ],
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: !_busy && _current && _reviewed
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ResultsScreen(analysis: _analysis!),
                    ),
                  );
                }
              : null,
          child: const Text('Continue to results'),
        ),
      ]),
    );
  }
}

class _UnmatchedCard extends StatelessWidget {
  final UnmatchedFragment fragment;
  final bool enabled;
  final ValueChanged<IngredientSuggestion> onSelected;

  const _UnmatchedCard({
    required this.fragment,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unresolved: ${fragment.text}',
              style: const TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Suggestions require your review. Selecting one edits the text; check it again before continuing.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: fragment.suggestions.map((suggestion) {
                return ActionChip(
                  label: Text(suggestion.name),
                  onPressed: enabled ? () => onSelected(suggestion) : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
