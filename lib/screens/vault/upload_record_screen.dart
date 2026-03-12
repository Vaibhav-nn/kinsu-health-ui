import 'package:flutter/material.dart';

import '../../core/theme.dart';

class UploadRecordScreen extends StatefulWidget {
  const UploadRecordScreen({super.key});

  @override
  State<UploadRecordScreen> createState() => _UploadRecordScreenState();
}

class _UploadRecordScreenState extends State<UploadRecordScreen> {
  int _step = 1;
  String _selectedType = 'Lab Report';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Record'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: List.generate(3, (index) {
              final active = index + 1 <= _step;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: active ? KinsuTheme.primary : KinsuTheme.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          if (_step == 1) ...[
            const Text(
              'Select document type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...[
              'Lab Report',
              'Prescription',
              'Imaging (X-Ray/CT)',
              'Discharge Summary',
              'Handwritten Notes',
            ].map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selectedType = item),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedType == item
                            ? KinsuTheme.primary
                            : KinsuTheme.divider,
                        width: _selectedType == item ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file_outlined),
                        const SizedBox(width: 10),
                        Expanded(child: Text(item)),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => setState(() => _step = 2),
              child: const Text('Continue'),
            ),
          ] else if (_step == 2) ...[
            const Text(
              'Upload document',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: KinsuTheme.divider),
              ),
              child: const Column(
                children: [
                  Icon(Icons.upload_file, size: 42, color: KinsuTheme.primary),
                  SizedBox(height: 10),
                  Text('Tap to upload or take a photo'),
                  SizedBox(height: 6),
                  Text(
                    'Supports PDF, JPG, PNG',
                    style: TextStyle(color: KinsuTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _step = 3),
                    icon: const Icon(Icons.folder_open_outlined),
                    label: const Text('Choose File'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _step = 3),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: KinsuTheme.cardDecoration,
              child: Column(
                children: [
                  const Icon(Icons.check_circle,
                      size: 50, color: KinsuTheme.primary),
                  const SizedBox(height: 12),
                  const Text(
                    'Upload successful',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_selectedType has been added to your vault and linked to extracted parameters.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: KinsuTheme.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: KinsuTheme.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text('Hemoglobin: 14.1')),
                        Chip(label: Text('RBC: 4.8M')),
                        Chip(label: Text('WBC: 7.2K')),
                        Chip(label: Text('Platelets: 245K')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
