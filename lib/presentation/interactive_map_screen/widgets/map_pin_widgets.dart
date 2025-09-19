import 'package:flutter/material.dart';

/// Simple filter options for pins
class PinFilterOptions {
  final bool showShelters;
  final bool showAlerts;
  final bool showCommunityPins;
  
  const PinFilterOptions({
    this.showShelters = true,
    this.showAlerts = true,
    this.showCommunityPins = true,
  });
  
  static PinFilterOptions defaultFilters() {
    return const PinFilterOptions();
  }
}

/// Simple filter bottom sheet
class PinFilterBottomSheet extends StatelessWidget {
  final PinFilterOptions currentFilters;
  final Function(PinFilterOptions) onFiltersChanged;
  
  const PinFilterBottomSheet({
    Key? key,
    required this.currentFilters,
    required this.onFiltersChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Filter Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('Filter options temporarily disabled'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Simple pin creation bottom sheet
class PinCreationBottomSheet extends StatelessWidget {
  final double latitude;
  final double longitude;
  final Function(String, String) onPinCreated;
  
  const PinCreationBottomSheet({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.onPinCreated,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Create Pin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('Pin creation temporarily disabled'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Simple pin details popup
class PinDetailsPopup extends StatelessWidget {
  final Map<String, dynamic> pinData;
  
  const PinDetailsPopup({
    Key? key,
    required this.pinData,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pin Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Pin details temporarily disabled'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple pin search bar
class PinSearchBar extends StatelessWidget {
  final Function(String) onSearch;
  
  const PinSearchBar({
    Key? key,
    required this.onSearch,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search pins...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: onSearch,
      ),
    );
  }
}