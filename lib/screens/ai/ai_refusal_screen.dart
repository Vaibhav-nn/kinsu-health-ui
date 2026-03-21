import 'package:flutter/material.dart';

class AiRefusalScreen extends StatelessWidget {
  const AiRefusalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety Response')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.health_and_safety_outlined,
                size: 54,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(height: 12),
              const Text(
                'I can’t provide a diagnosis or dosage changes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please consult your doctor for medication, diagnosis, or emergency decisions.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Chat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
