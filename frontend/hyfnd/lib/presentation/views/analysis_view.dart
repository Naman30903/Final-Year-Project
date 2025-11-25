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
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyze News'),
      ),
      body: Consumer<NewsAnalysisProvider>(
        builder: (context, provider, child) {
          if (provider.state == AnalysisState.loading) {
            return const LoadingIndicator(message: 'Analyzing article...');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Input Type',
                            style: TextStyle(
                              fontSize: 16,
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
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _selectedType = newSelection.first;
                                _contentController.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
                                return 'Please enter ${_selectedType == 'text' ? 'content' : 'URL'}';
                              }

                              if (_selectedType == 'text' &&
                                  value.trim().length < 50) {
                                return 'Content must be at least 50 characters';
                              }

                              if (_selectedType == 'url' &&
                                  !Uri.tryParse(value)!.hasScheme) {
                                return 'Please enter a valid URL';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _analyzeNews,
                    icon: const Icon(Icons.psychology),
                    label: const Text('Analyze Article'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
