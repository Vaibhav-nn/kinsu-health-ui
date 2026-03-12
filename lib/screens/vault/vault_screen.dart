import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'lab_trends_screen.dart';
import 'record_detail_screen.dart';
import 'upload_record_screen.dart';
import 'vault_models.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _quickFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final records = vaultRecords.where((record) {
      final matchesQuery = _query.isEmpty ||
          record.title.toLowerCase().contains(_query.toLowerCase()) ||
          record.hospital.toLowerCase().contains(_query.toLowerCase()) ||
          record.tags
              .any((tag) => tag.toLowerCase().contains(_query.toLowerCase()));

      if (!matchesQuery) return false;
      if (_quickFilter == 'All') return true;
      if (_quickFilter == 'Lab Reports') return record.type == 'Lab Report';
      if (_quickFilter == 'Prescriptions') return record.type == 'Prescription';
      if (_quickFilter == 'Imaging') return record.type == 'Imaging';
      return record.type == 'Discharge Summary';
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom:
                      BorderSide(color: KinsuTheme.divider.withOpacity(0.7)),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Health Vault',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LabTrendsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.trending_up),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UploadRecordScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _query = value),
                          decoration: InputDecoration(
                            hintText: 'Search records...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _query = '');
                                    },
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.tune, size: 18),
                        label: const Text('Filters'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'All',
                        'Lab Reports',
                        'Prescriptions',
                        'Imaging',
                        'Summaries',
                      ].map((label) {
                        final isActive = _quickFilter == label;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            selected: isActive,
                            label: Text(label),
                            onSelected: (_) =>
                                setState(() => _quickFilter = label),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '${records.length} records',
                    style: const TextStyle(
                      fontSize: 12,
                      color: KinsuTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...records.map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RecordDetailScreen(record: record),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: KinsuTheme.cardDecoration,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: record.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(record.icon, color: record.color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      record.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      record.hospital,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: KinsuTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        Text(
                                          record.date,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: KinsuTheme.textSecondary,
                                          ),
                                        ),
                                        if (record.patient != 'Self')
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF5F3FF),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              record.patient,
                                              style: const TextStyle(
                                                color: Color(0xFF6D28D9),
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ...record.tags.map(
                                          (tag) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: KinsuTheme.background,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              tag,
                                              style:
                                                  const TextStyle(fontSize: 10),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: KinsuTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
