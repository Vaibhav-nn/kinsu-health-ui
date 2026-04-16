import 'package:flutter/material.dart';
import 'package:kinsu_health/widgets/ios_back_button.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/family_provider.dart';

class AddFamilyMemberScreen extends StatefulWidget {
  const AddFamilyMemberScreen({super.key});

  @override
  State<AddFamilyMemberScreen> createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends State<AddFamilyMemberScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  String _relation = '';
  DateTime? _dob;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _toE164(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) return digits;
    if (digits.startsWith('0')) return '+91${digits.substring(1)}';
    if (digits.length == 10) return '+91$digits';
    return '+$digits';
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) return;

    setState(() => _isSaving = true);

    final ok = await context.read<FamilyProvider>().addMember(
          displayName: name,
          phoneE164: _toE164(phone),
          relation: _relation.isEmpty ? null : _relation,
          dateOfBirth: _dob,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family member linked successfully.')),
      );
      Navigator.pop(context, true);
    } else {
      final error = context.read<FamilyProvider>().error ??
          'Failed to add family member.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: const IosBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Add Family Member'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Full Name *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number *',
              hintText: '+919876543210',
            ),
          ),
          const SizedBox(height: 12),
          const Text('Relationship',
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
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KinsuTheme.primaryLight.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'You can switch to this family profile from Home and log vitals/track records on their behalf.',
              style: TextStyle(color: KinsuTheme.textPrimary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: canSave && !_isSaving ? _save : null,
            child: Text(_isSaving ? 'Saving...' : 'Link Family Member'),
          ),
        ],
      ),
    );
  }
}
