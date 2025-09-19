/// Simplified interactive map screen 
import 'package:flutter/material.dart';

class InteractiveMapScreenEnhanced extends StatefulWidget {
  const InteractiveMapScreenEnhanced({Key? key}) : super(key: key);

  @override
  State<InteractiveMapScreenEnhanced> createState() => _InteractiveMapScreenEnhancedState();
}

class _InteractiveMapScreenEnhancedState extends State<InteractiveMapScreenEnhanced> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Map'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Interactive Map',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Enhanced map features temporarily disabled',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
