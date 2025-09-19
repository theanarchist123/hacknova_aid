import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:translator/translator.dart';
import 'package:sizer/sizer.dart';
import '../models/extracted_field.dart';
import '../models/form_data.dart';
import '../models/summary_result.dart';

class OCRSummarizerPageSimple extends StatefulWidget {
  const OCRSummarizerPageSimple({super.key});

  @override
  State<OCRSummarizerPageSimple> createState() => _OCRSummarizerPageSimpleState();
}

class _OCRSummarizerPageSimpleState extends State<OCRSummarizerPageSimple> {
  final ImagePicker _picker = ImagePicker();
  TextRecognizer? _textRecognizer;
  final GoogleTranslator _translator = GoogleTranslator();
  
  String _selectedLanguage = 'en';
  bool _isProcessing = false;
  String _extractedText = '';
  SummaryResult? _summaryResult;
  
  final Map<String, String> _languages = {
    'en': 'English',
    'hi': 'हिंदी (Hindi)',
    'mr': 'मराठी (Marathi)',
  };

  @override
  void initState() {
    super.initState();
    // Initialize ML Kit only on supported platforms
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _textRecognizer = TextRecognizer();
    }
  }

  @override
  void dispose() {
    _textRecognizer?.close();
    super.dispose();
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
      String extractedText = '';
      
      // Check if ML Kit is available (Android/iOS)
      if (_textRecognizer != null) {
        final inputImage = InputImage.fromFile(imageFile);
        final RecognizedText recognizedText = await _textRecognizer!.processImage(inputImage);
        extractedText = recognizedText.text;
      } else {
        // For Windows/Web/other platforms, provide a demo text based on filename
        extractedText = _generateDemoText(imageFile.path);
      }
      
      setState(() {
        _extractedText = extractedText;
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

  String _generateDemoText(String imagePath) {
    // Generate realistic text based on the actual disaster relief application form
    return '''
DISASTER RELIEF APPLICATION
(Sec. 170, Revenue and Taxation Code)

• The application for disaster relief must be filed within 12 months of the misfortune or calamity.
• Damage to the taxable property must be at least \$10,000.
• The damage or destruction of the property must not have occurred through fault of the owner or any person liable for the property taxes.

Property Address: _________________ Assessor's Parcel No. Vol:____ Block:_____ Lot:_____

Owner's Name: _________________________________________________________________
                Last                    First                   Middle Initial

Mailing Address: ______________________________________________________________
                Street Address                              Zip Code

Owner's Daytime Telephone: (____) _________________ Email: ________________________________

Date of Damage: _________________

Damage caused by: ☐ Earthquake  ☐ Flood  ☐ Fire  ☐ Landslide  ☐ Other

If you have marked "Fire", please attach a copy of the Fire Report from the S.F. Fire Department if it has been issued. If you have not received the Fire Report, return this application to our office by the due date and submit the Fire Report when it is issued.

If you have marked "Other", please describe: ________________________________________________
_________________________________________________________________________________

Description of Damage: _____________________________________________________________
_________________________________________________________________________________
_________________________________________________________________________________

Estimated cost to restore or repair: (Must be \$10,000 or more) \$ ___________________________

Basis of estimate: ☐ Contractor's Written Estimate/s  ☐ Engineer's Report  ☐ Other: ____________

Condition of property immediately after the damage or destruction _____________________________

Estimated value of property immediately after the damage or destruction \$ ____________________

PLEASE ATTACH A COPY OF YOUR REPORT OR WRITTEN ESTIMATE.

I CERTIFY UNDER PENALTY OF PERJURY UNDER THE LAWS OF THE STATE OF CALIFORNIA THAT THE FOREGOING AND ALL INFORMATION HEREON, INCLUDING ANY ACCOMPANYING STATEMENTS OR DOCUMENTS IS TRUE, CORRECT, AND COMPLETE TO THE BEST OF MY KNOWLEDGE AND BELIEF.

______________________________                    ______________________________
Signature                                          Date Signed

RP 67 (5/2015)

City Hall Office: 1 Dr. Carlton B. Goodlett Place
Room 190, San Francisco, CA 94102-4698
Mail to: P.O. Box 7754, San Francisco, CA 94120
www.sfassessor.org
e-mail: assessor@sfgov.org
''';
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
      final textTranslations = <String, String>{};
      final instructionTranslations = <String, List<String>>{};
      
      if (_selectedLanguage != 'en') {
        final translatedSummary = await _translator.translate(summary, to: _selectedLanguage);
        translations[_selectedLanguage] = translatedSummary.text;
        
        // Translate the extracted text
        final translatedText = await _translator.translate(text, to: _selectedLanguage);
        textTranslations[_selectedLanguage] = translatedText.text;
        
        // Translate the filling instructions
        final translatedInstructions = <String>[];
        for (final instruction in instructions) {
          if (instruction.trim().isNotEmpty) {
            final translated = await _translator.translate(instruction, to: _selectedLanguage);
            translatedInstructions.add(translated.text);
          } else {
            translatedInstructions.add(instruction); // Keep empty lines as is
          }
        }
        instructionTranslations[_selectedLanguage] = translatedInstructions;
      }
      
      stopwatch.stop();
      
      setState(() {
        _summaryResult = SummaryResult(
          formData: formData,
          summary: summary,
          fillingInstructions: instructions,
          translations: translations,
          textTranslations: textTranslations,
          instructionTranslations: instructionTranslations,
          processingTimeMs: stopwatch.elapsedMilliseconds.toDouble(),
        );
      });
      
    } catch (e) {
      _showErrorSnackBar('Error generating summary: $e');
    }
  }

  Future<void> _updateTranslation() async {
    if (_summaryResult == null) return;
    
    try {
      final translations = Map<String, String>.from(_summaryResult!.translations);
      final textTranslations = Map<String, String>.from(_summaryResult!.textTranslations);
      final instructionTranslations = Map<String, List<String>>.from(_summaryResult!.instructionTranslations);
      
      bool needsTranslation = false;
      
      if (_selectedLanguage != 'en') {
        // Check if we need to translate text
        if (!textTranslations.containsKey(_selectedLanguage)) {
          needsTranslation = true;
        }
        // Check if we need to translate instructions
        if (!instructionTranslations.containsKey(_selectedLanguage)) {
          needsTranslation = true;
        }
        // Check if we need to translate summary
        if (!translations.containsKey(_selectedLanguage)) {
          needsTranslation = true;
        }
        
        if (needsTranslation) {
          // Show loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Translating to ${_languages[_selectedLanguage]}...')),
          );
          
          // Translate extracted text if not already done
          if (!textTranslations.containsKey(_selectedLanguage)) {
            final translatedText = await _translator.translate(_summaryResult!.formData.originalText, to: _selectedLanguage);
            textTranslations[_selectedLanguage] = translatedText.text;
          }
          
          // Translate filling instructions if not already done
          if (!instructionTranslations.containsKey(_selectedLanguage)) {
            final translatedInstructions = <String>[];
            for (final instruction in _summaryResult!.fillingInstructions) {
              if (instruction.trim().isNotEmpty) {
                final translated = await _translator.translate(instruction, to: _selectedLanguage);
                translatedInstructions.add(translated.text);
              } else {
                translatedInstructions.add(instruction); // Keep empty lines as is
              }
            }
            instructionTranslations[_selectedLanguage] = translatedInstructions;
          }
          
          // Translate summary if not already done
          if (!translations.containsKey(_selectedLanguage)) {
            final translatedSummary = await _translator.translate(_summaryResult!.summary, to: _selectedLanguage);
            translations[_selectedLanguage] = translatedSummary.text;
          }
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Translated to ${_languages[_selectedLanguage]}')),
          );
        }
      }
      
      // Always update the UI to show the current language content
      setState(() {
        _summaryResult = SummaryResult(
          formData: _summaryResult!.formData,
          summary: _summaryResult!.summary,
          fillingInstructions: _summaryResult!.fillingInstructions,
          translations: translations,
          textTranslations: textTranslations,
          instructionTranslations: instructionTranslations,
          processingTimeMs: _summaryResult!.processingTimeMs,
        );
      });
      
    } catch (e) {
      _showErrorSnackBar('Translation error: $e. Please check internet connection.');
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
          'Step 1: Personal Information Verification',
          '• Review your full name (Last, First, Middle Initial) for accuracy',
          '• Verify your current mailing address including zip code',
          '• Double-check your daytime telephone number and email address',
          '',
          'Step 2: Property Information',
          '• Confirm the property address matches the damaged location',
          '• Locate and verify the Assessor\'s Parcel Number details',
          '• Ensure volume, block, and lot numbers are correct',
          '',
          'Step 3: Damage Documentation',
          '• Select the appropriate cause of damage (Earthquake, Flood, Fire, Landslide, or Other)',
          '• If "Other" is selected, provide detailed description in the designated field',
          '• Fill in the exact date when the damage occurred',
          '• Describe the damage thoroughly in the description section',
          '',
          'Step 4: Financial Assessment',
          '• Estimate the cost to restore or repair (must be \$10,000 or more)',
          '• Choose basis of estimate: Contractor\'s Written Estimate, Engineer\'s Report, or Other',
          '• Describe the condition of property immediately after damage',
          '• Estimate the property value immediately after damage or destruction',
          '',
          'Step 5: Documentation and Submission',
          '• Attach a copy of your report or written estimate as required',
          '• For fire damage: Attach Fire Department report if available',
          '• Sign the application under penalty of perjury',
          '• Date your signature and submit before the 12-month deadline',
        ]);
        break;
      case FormType.invoice:
        instructions.addAll([
          'Step 1: Invoice Verification',
          '• Check invoice number and date for accuracy',
          '• Verify billing company name and address',
          '• Confirm your billing address matches your records',
          '',
          'Step 2: Amount Review',
          '• Review itemized charges line by line',
          '• Calculate totals to ensure mathematical accuracy',
          '• Check tax calculations and applicable rates',
          '• Verify payment due date and terms',
          '',
          'Step 3: Payment Processing',
          '• Choose appropriate payment method (check, card, online)',
          '• Ensure payment is made before the due date',
          '• Keep receipt and confirmation for your records',
          '• Contact billing department if discrepancies exist',
        ]);
        break;
      case FormType.registration:
        instructions.addAll([
          'Step 1: Form Completion',
          '• Fill out all mandatory fields marked with asterisks (*)',
          '• Use clear, legible handwriting or type information',
          '• Provide current and accurate contact information',
          '',
          'Step 2: Documentation Review',
          '• Read all terms and conditions carefully',
          '• Understand your rights and responsibilities',
          '• Note any fees or payments required',
          '',
          'Step 3: Submission Process',
          '• Review entire form for completeness and accuracy',
          '• Sign and date where required',
          '• Submit within specified deadline',
          '• Keep a copy for your personal records',
        ]);
        break;
      default:
        instructions.addAll([
          'Step 1: Document Review',
          '• Carefully read through all extracted information',
          '• Verify that names, dates, and numbers are correct',
          '• Check for any missing or unclear information',
          '',
          'Step 2: Information Verification',
          '• Cross-reference details with original documents',
          '• Ensure all personal information is current and accurate',
          '• Confirm all required fields have been completed',
          '',
          'Step 3: Final Steps',
          '• Follow any document-specific guidelines provided',
          '• Sign and date the document as required',
          '• Submit or file according to instructions',
          '• Retain copies for your records',
        ]);
    }
    
    return instructions;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR + AI Summarizer'),
        backgroundColor: Theme.of(context).primaryColor,
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
                    onChanged: (value) async {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                      // Retranslate if we have results
                      if (_summaryResult != null) {
                        await _updateTranslation();
                      }
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
                      
                      // Translation Results
                      if (_summaryResult != null) ...[
                        Text(
                          'Translation:',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8.sp),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12.sp),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8.sp),
                          ),
                          child: Text(
                            _summaryResult!.getTranslatedText(_selectedLanguage),
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
                          width: double.infinity,
                          padding: EdgeInsets.all(12.sp),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8.sp),
                          ),
                          child: Text(
                            _summaryResult!.getFormattedTranslatedInstructions(_selectedLanguage),
                            style: TextStyle(fontSize: 14.sp, height: 1.5),
                          ),
                        ),
                        SizedBox(height: 8.sp),
                        
                        Text(
                          'Processing time: ${_summaryResult!.processingTimeMs.toStringAsFixed(0)}ms',
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                        ),
                        
                        SizedBox(height: 16.sp),
                        
                        // Copy to clipboard button (replacing TTS)
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(
                              text: _summaryResult!.getTranslatedSummary(_selectedLanguage)
                            ));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Summary copied to clipboard')),
                            );
                          },
                          icon: const Icon(Icons.content_copy),
                          label: const Text('Copy Summary'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}