/// Model representing handwritten exam marks table data.
/// Supports both table formats:
/// - Type 1: Questions 1, 2, 3, 4
/// - Type 2: Questions 5, 6, 7, 8
/// Rows: Parts a, b, c, d, e, f, g
/// Non-numeric or blank entries are represented as 'N/A' and calculated as 0.
class MarksTableData {
  static const List<String> type1Questions = ['1', '2', '3', '4'];
  static const List<String> type2Questions = ['5', '6', '7', '8'];
  static const List<String> parts = ['a', 'b', 'c', 'd', 'e', 'f', 'g'];

  final List<String> questions;
  final String tableType; // '1-4' or '5-8'

  /// Map of question -> part -> mark string (e.g. marks['1']['a'] = '7' or 'N/A')
  final Map<String, Map<String, String>> cellMarks;

  final Map<String, String> detectedTotals;
  final String? detectedGrandTotal;
  final String? imagePath;
  final double confidenceScore;
  final DateTime scannedAt;
  final bool isVerified;

  MarksTableData({
    List<String>? questions,
    String? tableType,
    required this.cellMarks,
    this.detectedTotals = const {},
    this.detectedGrandTotal,
    this.imagePath,
    this.confidenceScore = 0.985,
    DateTime? scannedAt,
    this.isVerified = false,
  })  : tableType = tableType ?? (questions?.first == '1' ? '1-4' : '5-8'),
        questions = questions ??
            (tableType == '1-4' ? type1Questions : type2Questions),
        scannedAt = scannedAt ?? DateTime.now();

  /// Gets mark for question and part. Returns 'N/A' if empty or null.
  String getMark(String question, String part) {
    final val = cellMarks[question]?[part]?.trim();
    if (val == null || val.isEmpty) {
      return 'N/A';
    }
    return val;
  }

  /// Parses a cell value into numeric marks. 'N/A', blanks or non-numbers evaluate to 0.0.
  static double parseMarkValue(String? text) {
    if (text == null) return 0.0;
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.toUpperCase() == 'N/A' || trimmed == '/' || trimmed == '-') {
      return 0.0;
    }
    return double.tryParse(trimmed) ?? 0.0;
  }

  /// Calculates numeric sum of marks for a given question column. 'N/A' is counted as 0.
  double calculateColumnTotal(String question) {
    final colMarks = cellMarks[question];
    if (colMarks == null) return 0.0;
    double sum = 0.0;
    for (final part in parts) {
      final val = colMarks[part];
      sum += parseMarkValue(val);
    }
    return sum;
  }

  /// Calculates the grand total across all questions. 'N/A' is counted as 0.
  double calculateGrandTotal() {
    double grandTotal = 0.0;
    for (final q in questions) {
      grandTotal += calculateColumnTotal(q);
    }
    return grandTotal;
  }

  /// Convenience getter for grand total
  double get grandTotal => calculateGrandTotal();

  MarksTableData copyWith({
    List<String>? questions,
    String? tableType,
    Map<String, Map<String, String>>? cellMarks,
    Map<String, String>? detectedTotals,
    String? detectedGrandTotal,
    String? imagePath,
    double? confidenceScore,
    DateTime? scannedAt,
    bool? isVerified,
  }) {
    final activeTableType = tableType ?? this.tableType;
    final activeQuestions = questions ??
        (activeTableType == '1-4' ? type1Questions : type2Questions);

    return MarksTableData(
      tableType: activeTableType,
      questions: activeQuestions,
      cellMarks: cellMarks ??
          this.cellMarks.map(
                (k, v) => MapEntry(k, Map<String, String>.from(v)),
              ),
      detectedTotals: detectedTotals ?? Map.from(this.detectedTotals),
      detectedGrandTotal: detectedGrandTotal ?? this.detectedGrandTotal,
      imagePath: imagePath ?? this.imagePath,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      scannedAt: scannedAt ?? this.scannedAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }


  /// Factory creating an empty table with all 'N/A' values
  factory MarksTableData.empty({String? imagePath, String tableType = '1-4'}) {
    final questions = tableType == '1-4' ? type1Questions : type2Questions;
    final emptyMap = <String, Map<String, String>>{};
    for (final q in questions) {
      emptyMap[q] = {for (final p in parts) p: 'N/A'};
    }
    return MarksTableData(
      tableType: tableType,
      questions: questions,
      cellMarks: emptyMap,
      imagePath: imagePath,
    );
  }
}
