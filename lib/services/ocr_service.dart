import 'dart:io';
import 'dart:typed_data';

class OcrService {
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

  Future<String> extractText(Uint8List imageBytes) async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      throw const OcrException(
        'Local Python OCR is available only in the desktop app.',
      );
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
}

class OcrException implements Exception {
  const OcrException(this.message);

  final String message;
}
