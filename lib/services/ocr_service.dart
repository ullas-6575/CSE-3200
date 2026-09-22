import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  TextRecognizer? _textRecognizer;

  // Change this when the virtual environment's Python executable is elsewhere.
  // Example: --dart-define=TROCR_PYTHON=/full/path/to/backend/.venv/bin/python
  static const String _pythonExecutable = String.fromEnvironment(
    'TROCR_PYTHON',
    defaultValue: 'python',
  );

  // This path is relative to the Flutter project's working directory.
  static const String _scriptPath = String.fromEnvironment(
    'TROCR_SCRIPT',
    defaultValue: 'backend/main.py',
  );

  Future<String> extractText(Uint8List imageBytes, {String? imagePath}) async {
    if (Platform.isAndroid || Platform.isIOS) {
      if (imagePath == null) {
        throw const OcrException('The selected image could not be opened.');
      }
      try {
        final TextRecognizer recognizer = _textRecognizer ??= TextRecognizer();
        final RecognizedText result = await recognizer.processImage(
          InputImage.fromFilePath(imagePath),
        );
        return result.text;
      } catch (error) {
        throw OcrException('Could not read text from the image: $error');
      }
    }

    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      throw const OcrException('OCR is not supported on this platform.');
    }

    final File script = File(_scriptPath);
    if (!await script.exists()) {
      throw const OcrException(
        'Cannot find $_scriptPath. Run the desktop app from the project folder '
        'or set TROCR_SCRIPT.',
      );
    }

    final File imageFile = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'trocr-${DateTime.now().microsecondsSinceEpoch}.jpg',
    );

    try {
      await imageFile.writeAsBytes(imageBytes, flush: true);
      final ProcessResult result = await Process.run(
        _pythonExecutable,
        <String>[script.path, imageFile.path],
        runInShell: Platform.isWindows,
      );

      if (result.exitCode != 0) {
        final String details = result.stderr.toString().trim();
        throw OcrException(
          details.isEmpty ? 'Local TrOCR failed.' : details,
        );
      }

      return result.stdout.toString().trim();
    } on OcrException {
      rethrow;
    } on ProcessException {
      throw const OcrException(
        'Cannot start $_pythonExecutable. Install Python or set TROCR_PYTHON.',
      );
    } finally {
      if (await imageFile.exists()) await imageFile.delete();
    }
  }

  Future<void> dispose() async {
    await _textRecognizer?.close();
    _textRecognizer = null;
  }
}

class OcrException implements Exception {
  const OcrException(this.message);

  final String message;
}
