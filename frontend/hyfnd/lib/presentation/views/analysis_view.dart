import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/news_analysis_provider.dart';
import '../widgets/loading_indicator.dart';

class AnalysisView extends StatefulWidget {
  const AnalysisView({super.key});

  @override
  State<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  String _selectedType = 'text';

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _analyzeNews() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<NewsAnalysisProvider>();

    await provider.analyzeNews(
      _contentController.text.trim(),
      _selectedType,
    );

    if (!mounted) return;

    if (provider.state == AnalysisState.success) {
      context.push('/result');
    } else if (provider.state == AnalysisState.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'An error occurred'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Analyze News')),
      body: Consumer<NewsAnalysisProvider>(
        builder: (context, provider, child) {
          if (provider.state == AnalysisState.loading) {
            return LoadingIndicator(
              message: _selectedType == 'url'
                  ? 'Fetching and analyzing article...'
                  : 'Analyzing article...',
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Input type selector ──
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Input Type',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'text',
                                label: Text('Text'),
                                icon: Icon(Icons.article),
                              ),
                              ButtonSegment(
                                value: 'url',
                                label: Text('URL'),
                                icon: Icon(Icons.link),
                              ),
                            ],
                            selected: {_selectedType},
                            onSelectionChanged: (sel) {
                              setState(() {
                                _selectedType = sel.first;
                                _contentController.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Content input ──
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedType == 'text'
                                ? 'Article Content'
                                : 'Article URL',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedType == 'text'
                                ? 'Paste the full article text below'
                                : 'Paste a news article link — we\'ll fetch and analyze it',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _contentController,
                            maxLines: _selectedType == 'text' ? 10 : 1,
                            decoration: InputDecoration(
                              hintText: _selectedType == 'text'
                                  ? 'Paste the article content here (minimum 50 characters)...'
                                  : 'https://example.com/news-article',
                              prefixIcon: Icon(
                                _selectedType == 'text'
                                    ? Icons.text_fields
                                    : Icons.link,
                              ),
                            ),
                            keyboardType: _selectedType == 'url'
                                ? TextInputType.url
                                : TextInputType.multiline,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter ${_selectedType == 'text' ? 'content' : 'a URL'}';
                              }

                              if (_selectedType == 'text' &&
                                  value.trim().length < 50) {
                                return 'Content must be at least 50 characters';
                              }

                              if (_selectedType == 'url') {
                                final uri = Uri.tryParse(value.trim());
                                if (uri == null ||
                                    !uri.hasScheme ||
                                    !uri.hasAuthority) {
                                  return 'Please enter a valid URL (e.g. https://...)';
                                }
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_selectedType == 'url') ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Works best with standard news sites. Social media links are not supported.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Submit ──
                  ElevatedButton.icon(
                    onPressed: _analyzeNews,
                    icon: const Icon(Icons.psychology),
                    label: Text(
                      _selectedType == 'url'
                          ? 'Fetch & Analyze'
                          : 'Analyze Article',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
              ),
            ),
          );
        },
      ),
    );
  }
}
