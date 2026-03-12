import 'package:flutter/material.dart';

import '../../core/theme.dart';

class AddFamilyMemberScreen extends StatefulWidget {
  const AddFamilyMemberScreen({super.key});

  @override
  State<AddFamilyMemberScreen> createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends State<AddFamilyMemberScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _relation = '';
  String _bloodGroup = '';
  DateTime? _dob;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave =
        _nameController.text.trim().isNotEmpty && _relation.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Family Member'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: KinsuTheme.primaryLight.withOpacity(0.3),
                  child: const Icon(Icons.person_outline, size: 36),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Add Photo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Full Name *'),
          ),
          const SizedBox(height: 12),
          const Text('Relationship *',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Mother',
              'Father',
              'Spouse',
              'Son',
              'Daughter',
              'Sibling',
              'Other',
            ].map((item) {
              return ChoiceChip(
                selected: _relation == item,
                label: Text(item),
                onSelected: (_) => setState(() => _relation = item),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final selected = await showDatePicker(
                context: context,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                initialDate: DateTime(1990),
              );
              if (selected == null) return;
              setState(() => _dob = selected);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Date of Birth'),
              child: Text(
                _dob == null
                    ? 'Select date'
                    : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Blood Group',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                .map((item) => ChoiceChip(
                      selected: _bloodGroup == item,
                      label: Text(item),
                      onSelected: (_) => setState(() => _bloodGroup = item),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile Number (optional)',
              prefixText: '+91 ',
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KinsuTheme.primaryLight.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'As the primary account holder, you manage this profile under consent policy controls.',
              style: TextStyle(color: KinsuTheme.textPrimary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: canSave
                ? () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Family member added')),
                    );
                  }
                : null,
            child: Text(
                _relation.isEmpty ? 'Add Family Member' : 'Add $_relation'),
          ),
        ],
      ),
    );
  }
}
