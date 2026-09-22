import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class OcrService {
  OcrService({http.Client? client}) : _client = client ?? http.Client();

  // Override this at launch with --dart-define, for example:
  // --dart-define=OCR_ENDPOINT=http://192.168.1.10:8000/ocr
  static const String _endpointUrl = String.fromEnvironment(
    'OCR_ENDPOINT',
    defaultValue: 'http://localhost:8000/ocr',
  );
  final http.Client _client;

  Future<String> extractText(Uint8List imageBytes) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_endpointUrl))
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: 'captured-image.jpg',
          ),
        );
      final response = await _client.send(request);
      final body = await http.Response.fromStream(response);
      final Map<String, dynamic> data = jsonDecode(body.body);

      if (body.statusCode != 200) {
        throw OcrException(data['detail'] as String? ?? 'OCR failed.');
      }
      return data['text'] as String? ?? '';
    } on OcrException {
      rethrow;
    } catch (_) {
      throw const OcrException(
        'Cannot reach the OCR server. Start the Python server on port 8000.',
      );
    }
  }
}

class OcrException implements Exception {
  const OcrException(this.message);

  final String message;
}
