import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class OcrResultPage extends StatefulWidget {
  const OcrResultPage({
    super.key,
    required this.imageBytes,
    required this.extractedText,
  });

  final Uint8List imageBytes;
  final String extractedText;

  @override
  State<OcrResultPage> createState() => _OcrResultPageState();
}

class _OcrResultPageState extends State<OcrResultPage> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.extractedText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _verify() {
    final json = const JsonEncoder.withIndent('  ').convert({
      'text': _textController.text.trim(),
      'verifiedAt': DateTime.now().toIso8601String(),
    });
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => JsonResultPage(json: json)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review extracted data')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(widget.imageBytes, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),
            Text('Extracted text',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _textController,
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'OCR result will appear here',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _verify,
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Verify and create JSON'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JsonResultPage extends StatelessWidget {
  const JsonResultPage({super.key, required this.json});

  final String json;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Verified JSON')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: SelectableText(json),
        ),
      );
}
