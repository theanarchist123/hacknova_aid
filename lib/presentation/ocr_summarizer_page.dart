import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:translator/translator.dart';
import 'package:text_to_speech/text_to_speech.dart';
import 'package:sizer/sizer.dart';
import '../models/extracted_field.dart';
import '../models/form_data.dart';
import '../models/summary_result.dart';
import '../core/services/ocr_storage_service.dart';

class OCRSummarizerPage extends StatefulWidget {
  const OCRSummarizerPage({super.key});

  @override
  State<OCRSummarizerPage> createState() => _OCRSummarizerPageState();
}

class _OCRSummarizerPageState extends State<OCRSummarizerPage> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  final GoogleTranslator _translator = GoogleTranslator();
  final TextToSpeech _tts = TextToSpeech();
  
  String _selectedLanguage = 'en';
  bool _isProcessing = false;
  bool _isSpeaking = false;
  String _extractedText = '';
  SummaryResult? _summaryResult;
  
  final Map<String, String> _languages = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
  };

  @override
  void initState() {
    super.initState();
    _initializeTTS();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _tts.stop();
    super.dispose();
  }

  Future<void> _initializeTTS() async {
    // Initialize TTS - text_to_speech package handles platform-specific setup automatically
    try {
      await _tts.setLanguage(_selectedLanguage);
      await _tts.setRate(0.6);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('Error taking photo: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting image: $e');
    }
  }

  Future<void> _pickPDFFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        await _processPDF(file);
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting PDF: $e');
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _isProcessing = true;
      _extractedText = '';
      _summaryResult = null;
    });

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      setState(() {
        _extractedText = recognizedText.text;
      });

      if (_extractedText.isNotEmpty) {
        await _generateSummary(_extractedText, imageFile.path);
      } else {
        _showErrorSnackBar('No text found in the image');
      }
    } catch (e) {
      _showErrorSnackBar('Error processing image: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processPDF(File pdfFile) async {
    setState(() {
      _isProcessing = true;
      _extractedText = '';
      _summaryResult = null;
    });

    try {
      final bytes = await pdfFile.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      
      String text = '';
      for (int i = 0; i < document.pages.count; i++) {
        final PdfTextExtractor extractor = PdfTextExtractor(document);
        text += extractor.extractText(startPageIndex: i, endPageIndex: i);
        text += '\n';
      }
      
      document.dispose();
      
      setState(() {
        _extractedText = text.trim();
      });

      if (_extractedText.isNotEmpty) {
        await _generateSummary(_extractedText, pdfFile.path);
      } else {
        _showErrorSnackBar('No text found in the PDF');
      }
    } catch (e) {
      _showErrorSnackBar('Error processing PDF: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _generateSummary(String text, String sourceFile) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Detect form type
      final formType = _detectFormType(text);
      
      // Extract fields
      final extractedFields = _extractFields(text, formType);
      
      // Create form data
      final formData = FormData(
        formType: formType,
        originalText: text,
        extractedFields: extractedFields,
        processedAt: DateTime.now(),
        sourceFile: sourceFile,
      );
      
      // Generate summary
      final summary = _generateFormSummary(formData);
      
      // Generate filling instructions
      final instructions = _generateFillingInstructions(formData);
      
      // Translate if needed
      final translations = <String, String>{};
      if (_selectedLanguage != 'en') {
        final translatedSummary = await _translator.translate(summary, to: _selectedLanguage);
        translations[_selectedLanguage] = translatedSummary.text;
      }
      
      stopwatch.stop();
      
      setState(() {
        _summaryResult = SummaryResult(
          formData: formData,
          summary: summary,
          fillingInstructions: instructions,
          translations: translations,
          processingTimeMs: stopwatch.elapsedMilliseconds.toDouble(),
        );
      });
      
      // Save to local storage
      await _saveSummaryResult(_summaryResult!);
      
    } catch (e) {
      _showErrorSnackBar('Error generating summary: $e');
    }
  }

  Future<void> _saveSummaryResult(SummaryResult result) async {
    try {
      await OCRStorageService.saveSummaryResult(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Results saved locally'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save results: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  FormType _detectFormType(String text) {
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('application') || lowerText.contains('apply')) {
      return FormType.application;
    } else if (lowerText.contains('invoice') || lowerText.contains('bill') || lowerText.contains('amount due')) {
      return FormType.invoice;
    } else if (lowerText.contains('registration') || lowerText.contains('register')) {
      return FormType.registration;
    } else if (lowerText.contains('medical') || lowerText.contains('patient') || lowerText.contains('doctor')) {
      return FormType.medical;
    } else if (lowerText.contains('identification') || lowerText.contains('id') || lowerText.contains('passport')) {
      return FormType.identification;
    } else if (lowerText.contains('contract') || lowerText.contains('agreement')) {
      return FormType.contract;
    } else if (lowerText.contains('receipt') || lowerText.contains('purchased')) {
      return FormType.receipt;
    }
    
    return FormType.unknown;
  }

  List<ExtractedField> _extractFields(String text, FormType formType) {
    final fields = <ExtractedField>[];
    
    // Name extraction
    final nameRegex = RegExp(r'(?:name|nombre|nom|name)\s*[:]\s*([A-Za-z\s]+)', caseSensitive: false);
    final nameMatch = nameRegex.firstMatch(text);
    if (nameMatch != null) {
      fields.add(ExtractedField(
        fieldName: 'Name',
        value: nameMatch.group(1)!.trim(),
        confidence: 0.8,
        fieldType: 'text',
      ));
    }
    
    // Email extraction
    final emailRegex = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    final emailMatch = emailRegex.firstMatch(text);
    if (emailMatch != null) {
      fields.add(ExtractedField(
        fieldName: 'Email',
        value: emailMatch.group(0)!,
        confidence: 0.9,
        fieldType: 'email',
      ));
    }
    
    // Phone extraction
    final phoneRegex = RegExp(r'(?:\+?1[-.\s]?)?\(?([0-9]{3})\)?[-.\s]?([0-9]{3})[-.\s]?([0-9]{4})');
    final phoneMatch = phoneRegex.firstMatch(text);
    if (phoneMatch != null) {
      fields.add(ExtractedField(
        fieldName: 'Phone',
        value: phoneMatch.group(0)!,
        confidence: 0.8,
        fieldType: 'phone',
      ));
    }
    
    // Date extraction
    final dateRegex = RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b');
    final dateMatch = dateRegex.firstMatch(text);
    if (dateMatch != null) {
      fields.add(ExtractedField(
        fieldName: 'Date',
        value: dateMatch.group(0)!,
        confidence: 0.7,
        fieldType: 'date',
      ));
    }
    
    // Amount extraction (for invoices/receipts)
    if (formType == FormType.invoice || formType == FormType.receipt) {
      final amountRegex = RegExp(r'\$?\s*\d+\.?\d*');
      final amountMatches = amountRegex.allMatches(text);
      if (amountMatches.isNotEmpty) {
        fields.add(ExtractedField(
          fieldName: 'Amount',
          value: amountMatches.last.group(0)!,
          confidence: 0.7,
          fieldType: 'currency',
        ));
      }
    }
    
    return fields;
  }

  String _generateFormSummary(FormData formData) {
    final buffer = StringBuffer();
    buffer.writeln('Document Type: ${formData.getFormTypeDisplayName()}');
    buffer.writeln('Processed: ${formData.processedAt.toString().substring(0, 16)}');
    
    if (formData.extractedFields.isNotEmpty) {
      buffer.writeln('\nExtracted Information:');
      for (final field in formData.extractedFields) {
        buffer.writeln('• ${field.fieldName}: ${field.value}');
      }
    }
    
    return buffer.toString();
  }

  List<String> _generateFillingInstructions(FormData formData) {
    final instructions = <String>[];
    
    switch (formData.formType) {
      case FormType.application:
        instructions.addAll([
          'Review all personal information for accuracy',
          'Ensure all required fields are completed',
          'Attach any necessary supporting documents',
          'Sign and date the application before submitting',
        ]);
        break;
      case FormType.invoice:
        instructions.addAll([
          'Verify the billing amount and details',
          'Check payment due date',
          'Confirm billing address',
          'Process payment through approved methods',
        ]);
        break;
      case FormType.registration:
        instructions.addAll([
          'Complete all mandatory fields',
          'Provide valid contact information',
          'Review terms and conditions',
          'Submit within the specified deadline',
        ]);
        break;
      default:
        instructions.addAll([
          'Review all extracted information',
          'Verify accuracy of personal details',
          'Complete any missing required fields',
          'Follow document-specific guidelines',
        ]);
    }
    
    return instructions;
  }

  Future<void> _toggleTTS() async {
    if (_summaryResult == null) return;
    
    if (_isSpeaking) {
      await _tts.stop();
      setState(() {
        _isSpeaking = false;
      });
    } else {
      try {
        await _tts.setLanguage(_selectedLanguage);
        final textToSpeak = _summaryResult!.getTranslatedSummary(_selectedLanguage);
        await _tts.speak(textToSpeak);
        setState(() {
          _isSpeaking = true;
        });
        
        // Since text_to_speech doesn't have completion handler, 
        // we'll set a timer to reset the speaking state
        Future.delayed(Duration(milliseconds: textToSpeak.length * 100), () {
          if (mounted) {
            setState(() {
              _isSpeaking = false;
            });
          }
        });
      } catch (e) {
        _showErrorSnackBar('TTS Error: $e');
        setState(() {
          _isSpeaking = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _showSavedResults() async {
    try {
      final results = await OCRStorageService.getAllResults();
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Saved OCR Results'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: results.isEmpty
                ? const Center(child: Text('No saved results found'))
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final result = results[index];
                      return Card(
                        child: ListTile(
                          title: Text(result.formData.getFormTypeDisplayName()),
                          subtitle: Text(
                            'Processed: ${result.formData.processedAt.toString().substring(0, 16)}\n'
                            'Fields: ${result.formData.extractedFields.length}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              // Note: This would require adding an ID field to track database records
                              // For now, we'll show a placeholder
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Delete functionality coming soon')),
                              );
                            },
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            setState(() {
                              _summaryResult = result;
                              _extractedText = result.formData.originalText;
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error loading saved results: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR + AI Summarizer'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showSavedResults,
            tooltip: 'View Saved Results',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Language Selection
            Row(
              children: [
                Text(
                  'Language: ',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    isExpanded: true,
                    items: _languages.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                      _initializeTTS();
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.sp),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _pickImageFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                SizedBox(width: 8.sp),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
                SizedBox(width: 8.sp),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _pickPDFFile,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('PDF'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.sp),
            
            // Processing Indicator
            if (_isProcessing)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Processing document...'),
                  ],
                ),
              ),
            
            // Results Section
            if (!_isProcessing && (_extractedText.isNotEmpty || _summaryResult != null))
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Extracted Text
                      if (_extractedText.isNotEmpty) ...[
                        Text(
                          'Extracted Text:',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8.sp),
                        Container(
                          padding: EdgeInsets.all(12.sp),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8.sp),
                          ),
                          child: Text(
                            _extractedText,
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                        SizedBox(height: 16.sp),
                      ],
                      
                      // Summary Results
                      if (_summaryResult != null) ...[
                        Text(
                          'AI Summary:',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8.sp),
                        Container(
                          padding: EdgeInsets.all(12.sp),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            border: Border.all(color: Colors.blue.shade200),
                            borderRadius: BorderRadius.circular(8.sp),
                          ),
                          child: Text(
                            _summaryResult!.getTranslatedSummary(_selectedLanguage),
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                        SizedBox(height: 16.sp),
                        
                        Text(
                          'Filling Instructions:',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8.sp),
                        Container(
                          padding: EdgeInsets.all(12.sp),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            border: Border.all(color: Colors.green.shade200),
                            borderRadius: BorderRadius.circular(8.sp),
                          ),
                          child: Text(
                            _summaryResult!.getFormattedInstructions(),
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                        SizedBox(height: 8.sp),
                        
                        Text(
                          'Processing time: ${_summaryResult!.processingTimeMs.toStringAsFixed(0)}ms',
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _summaryResult != null
          ? FloatingActionButton(
              onPressed: _toggleTTS,
              child: Icon(_isSpeaking ? Icons.pause : Icons.play_arrow),
            )
          : null,
    );
  }
}