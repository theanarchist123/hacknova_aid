import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class OCRScreen extends StatefulWidget {
  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _processing = false;
  bool _showResult = false;
  String _raw = '';
  String _summary = '';

  Future<void> _select(ImageSource src) async {
    final picked = await _picker.pickImage(source: src, imageQuality: 80);
    if (picked == null) return;
    setState(() {
      _image = File(picked.path);
      _processing = true;
      _showResult = false;
      _raw = '';
      _summary = '';
    });
    await Future.delayed(const Duration(seconds: 1)); // mock OCR
    _raw = _mockRawText();
    await Future.delayed(const Duration(seconds: 1)); // mock summary
    _summary = _mockSummary();
    setState(() {
      _processing = false;
      _showResult = true;
    });
  }

  String _mockRawText() =>
      'SEVERE CYCLONIC STORM. Winds 120-140 km/h. Coastal evacuation for low zones. Fishermen stay ashore.';
  String _mockSummary() =>
      'CYCLONE ALERT:\n1. Move to safer shelter if low area.\n2. Stay indoors tomorrow.\n3. Do not go to sea.\n4. Keep phone charged & supplies ready.';

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _select(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _select(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR + AI Summarizer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _introCard(),
            const SizedBox(height: 16),
            if (!_processing && !_showResult) _uploadCard(),
            if (_processing) _processingCard(),
            if (_showResult) _resultCard(),
          ],
        ),
      ),
    );
  }

  Widget _introCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Convert complex government advisories into simple, actionable instructions.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeatureChip(label: 'Photo OCR'),
                _FeatureChip(label: 'AI Simplification'),
                _FeatureChip(label: 'Multi-language'),
                _FeatureChip(label: 'Offline Ready'),
              ],
            ),
          ],
        ),
      );

  Widget _uploadCard() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '1. Upload Advisory Image',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showPickerSheet,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade300, width: 1.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      size: 54, color: Colors.blue.shade500),
                  const SizedBox(height: 12),
                  const Text('Tap to pick or capture image',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('PNG • JPG • Clear text posters',
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ),
          if (_image != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _image!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ]
        ],
      );

  Widget _processingCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Processing...',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            SizedBox(height: 12),
            LinearProgressIndicator(),
            SizedBox(height: 12),
            Text('Simulating OCR + summarization (mock).',
                style: TextStyle(color: Colors.black54)),
          ],
        ),
      );

  Widget _resultCard() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Extracted Text',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
          _boxed(_raw),
          const SizedBox(height: 20),
          const Text('Simplified Guidance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _boxed(_summary),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () =>
                    setState(() {
                      _image = null;
                      _showResult = false;
                    }),
                icon: const Icon(Icons.refresh),
                label: const Text('New Image'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ],
          )
        ],
      );

  Widget _boxed(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text.isEmpty ? '(empty)' : text),
      );
}

class _FeatureChip extends StatelessWidget {
  final String label;
  const _FeatureChip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}