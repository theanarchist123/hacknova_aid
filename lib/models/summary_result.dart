import 'form_data.dart';

class SummaryResult {
  final FormData formData;
  final String summary;
  final List<String> fillingInstructions;
  final Map<String, String> translations;
  final Map<String, String> textTranslations; // For translated extracted text
  final Map<String, List<String>> instructionTranslations; // For translated instructions
  final double processingTimeMs;

  SummaryResult({
    required this.formData,
    required this.summary,
    required this.fillingInstructions,
    required this.translations,
    this.textTranslations = const {},
    this.instructionTranslations = const {},
    required this.processingTimeMs,
  });

  Map<String, dynamic> toJson() {
    return {
      'formData': formData.toJson(),
      'summary': summary,
      'fillingInstructions': fillingInstructions,
      'translations': translations,
      'textTranslations': textTranslations,
      'instructionTranslations': instructionTranslations.map((key, value) => MapEntry(key, value)),
      'processingTimeMs': processingTimeMs,
    };
  }

  factory SummaryResult.fromJson(Map<String, dynamic> json) {
    return SummaryResult(
      formData: FormData.fromJson(json['formData']),
      summary: json['summary'] ?? '',
      fillingInstructions: List<String>.from(json['fillingInstructions'] ?? []),
      translations: Map<String, String>.from(json['translations'] ?? {}),
      textTranslations: Map<String, String>.from(json['textTranslations'] ?? {}),
      instructionTranslations: (json['instructionTranslations'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, List<String>.from(value))) ?? {},
      processingTimeMs: json['processingTimeMs']?.toDouble() ?? 0.0,
    );
  }

  String getTranslatedSummary(String languageCode) {
    return translations[languageCode] ?? summary;
  }

  String getTranslatedText(String languageCode) {
    return textTranslations[languageCode] ?? formData.originalText;
  }

  List<String> getTranslatedInstructions(String languageCode) {
    return instructionTranslations[languageCode] ?? fillingInstructions;
  }

  String getFormattedInstructions() {
    return fillingInstructions.join('\n');
  }

  String getFormattedTranslatedInstructions(String languageCode) {
    final instructions = getTranslatedInstructions(languageCode);
    return instructions.join('\n');
  }
}
