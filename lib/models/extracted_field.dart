class ExtractedField {
  final String fieldName;
  final String value;
  final double confidence;
  final String fieldType;

  ExtractedField({
    required this.fieldName,
    required this.value,
    required this.confidence,
    required this.fieldType,
  });

  Map<String, dynamic> toJson() {
    return {
      'fieldName': fieldName,
      'value': value,
      'confidence': confidence,
      'fieldType': fieldType,
    };
  }

  factory ExtractedField.fromJson(Map<String, dynamic> json) {
    return ExtractedField(
      fieldName: json['fieldName'] ?? '',
      value: json['value'] ?? '',
      confidence: json['confidence']?.toDouble() ?? 0.0,
      fieldType: json['fieldType'] ?? '',
    );
  }

  @override
  String toString() {
    return '$fieldName: $value (${(confidence * 100).toStringAsFixed(1)}%)';
  }
}
