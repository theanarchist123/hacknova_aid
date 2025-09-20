import 'extracted_field.dart';

enum FormType {
  application,
  invoice,
  registration,
  medical,
  identification,
  contract,
  receipt,
  unknown
}

class FormData {
  final FormType formType;
  final String originalText;
  final List<ExtractedField> extractedFields;
  final DateTime processedAt;
  final String sourceFile;

  FormData({
    required this.formType,
    required this.originalText,
    required this.extractedFields,
    required this.processedAt,
    required this.sourceFile,
  });

  Map<String, dynamic> toJson() {
    return {
      'formType': formType.toString().split('.').last,
      'originalText': originalText,
      'extractedFields': extractedFields.map((field) => field.toJson()).toList(),
      'processedAt': processedAt.toIso8601String(),
      'sourceFile': sourceFile,
    };
  }

  factory FormData.fromJson(Map<String, dynamic> json) {
    return FormData(
      formType: FormType.values.firstWhere(
        (type) => type.toString().split('.').last == json['formType'],
        orElse: () => FormType.unknown,
      ),
      originalText: json['originalText'] ?? '',
      extractedFields: (json['extractedFields'] as List<dynamic>?)
          ?.map((field) => ExtractedField.fromJson(field))
          .toList() ?? [],
      processedAt: DateTime.parse(json['processedAt']),
      sourceFile: json['sourceFile'] ?? '',
    );
  }

  String getFormTypeDisplayName() {
    switch (formType) {
      case FormType.application:
        return 'Application Form';
      case FormType.invoice:
        return 'Invoice';
      case FormType.registration:
        return 'Registration Form';
      case FormType.medical:
        return 'Medical Document';
      case FormType.identification:
        return 'ID Document';
      case FormType.contract:
        return 'Contract';
      case FormType.receipt:
        return 'Receipt';
      case FormType.unknown:
        return 'Unknown Document';
    }
  }
}
