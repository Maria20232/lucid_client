import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/analysis_result.dart';
import '../models/ingredient.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class IngredientScreen extends StatefulWidget {
  final Ingredient ingredient;
  final String? recordedVersion;
  const IngredientScreen({
    super.key,
    required this.ingredient,
    this.recordedVersion,
  });
  @override
  State<IngredientScreen> createState() => _IngredientScreenState();
}

class _IngredientScreenState extends State<IngredientScreen> {
  Future<IngredientExplanation>? _explanation;
  String? _url;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    if (_url != app.baseUrl) {
      _url = app.baseUrl;
      _explanation = app.api.explanation(widget.ingredient.id);
    }
  }

  Future<void> _highlight() async {
    final app = AppScope.of(context);
    setState(() => _saving = true);
    try {
      await app.toggleHighlight(widget.ingredient);
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

  Future<void> _openSource(String source) async {
    final uri = Uri.tryParse(source);
    try {
      if (uri == null ||
          !['http', 'https'].contains(uri.scheme) ||
          uri.host.isEmpty ||
          !await launchUrl(uri)) {
        throw const FormatException(
          'Could not open this source. You can copy the URL below.',
        );
      }
    } on Object catch (error) {
      if (mounted) {
        showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final ingredient = widget.ingredient;
    final highlighted = app.isHighlighted(ingredient.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Ingredient details')),
      body: pageList([
        Text(
          ingredient.name,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        Text(
          '${ingredient.type} · ${ingredient.id}',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _saving ? null : _highlight,
          icon: Icon(highlighted ? Icons.bookmark : Icons.bookmark_border),
          label: Text(
            highlighted
                ? 'Remove personal highlight'
                : 'Highlight this ingredient',
          ),
        ),
        const SizedBox(height: 12),
        const NoticeBox(
          'Highlights are your personal choices. They apply to exact recognized ingredient IDs and do not establish dietary or allergen status.',
        ),
        FutureBuilder<IngredientExplanation>(
          future: _explanation,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  const NoticeBox(
                    'The explanation is unavailable. The ingredient record above is still available.',
                    warning: true,
                  ),
                  TextButton(
                    onPressed: () => setState(
                      () => _explanation = app.api.explanation(ingredient.id),
                    ),
                    child: const Text('Retry explanation'),
                  ),
                ],
              );
            }
            final explanation = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.recordedVersion != null &&
                    explanation.knowledgeVersion != widget.recordedVersion)
                  const NoticeBox(
                    'This explanation uses a newer or different KB than the saved result. Recheck the ingredient text to align versions.',
                    warning: true,
                  ),
                Text(
                  explanation.summary,
                  style: const TextStyle(fontSize: 17, height: 1.7),
                ),
                const SizedBox(height: 20),
                const NoticeBox(
                  'This is a taxonomy-based explanation. Detailed scientific or regulatory evidence is not yet included.',
                ),
                Text(
                  'Source: ${explanation.sourceName}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (explanation.taxonomyId != null)
                  Text(explanation.taxonomyId!),
                TextButton.icon(
                  onPressed: () => _openSource(explanation.sourceUrl),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open source'),
                ),
                SelectableText(
                  explanation.sourceUrl,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  explanation.knowledgeVersion,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            );
          },
        ),
      ]),
    );
  }
}
