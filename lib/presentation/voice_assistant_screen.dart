import 'package:flutter/material.dart';
import 'ocr_advisory_page.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({Key? key}) : super(key: key);

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  bool isListening = false;
  bool hasAnswer = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Disaster Assistant',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Center(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isListening = !isListening;
                  hasAnswer = isListening ? false : true;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: isListening ? 110 : 100,
                height: isListening ? 110 : 100,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: isListening ? 24 : 12,
                      spreadRadius: isListening ? 8 : 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 48),
              ),
            ),
          ),
          const SizedBox(height: 40),
          if (hasAnswer)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lead Message: Evacuate immediately!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.check_circle, color: Colors.black, size: 18),
                              SizedBox(width: 8),
                              Text('Move to higher ground', style: TextStyle(color: Colors.black)),
                            ],
                          ),
                          Row(
                            children: const [
                              Icon(Icons.check_circle, color: Colors.black, size: 18),
                              SizedBox(width: 8),
                              Text('Carry essentials', style: TextStyle(color: Colors.black)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Supporting Info: Flood warning issued for your area.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Nearest Shelter: City Hall, 1.2 km',
                        style: TextStyle(color: Colors.black, fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          'Sources: NDMA, IMD',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
              IconButton(
                icon: const Icon(Icons.replay, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VoiceAssistantScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.language, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdvisoryOCRPage()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.map, color: Colors.black),
                onPressed: () {
                  // Replace with your actual Hazard Map screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Scaffold(
                      appBar: AppBar(title: const Text('Hazard Map')),
                      body: const Center(child: Text('Hazard Map Page Placeholder')),
                    )),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
