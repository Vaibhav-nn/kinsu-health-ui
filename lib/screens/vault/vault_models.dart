import 'package:flutter/material.dart';

class VaultRecord {
  final String type;
  final String title;
  final String hospital;
  final String doctor;
  final String date;
  final String patient;
  final List<String> tags;
  final IconData icon;
  final Color color;

  const VaultRecord({
    required this.type,
    required this.title,
    required this.hospital,
    required this.doctor,
    required this.date,
    required this.patient,
    required this.tags,
    required this.icon,
    required this.color,
  });
}

const vaultRecords = <VaultRecord>[
  VaultRecord(
    type: 'Lab Report',
    title: 'Complete Blood Count (CBC)',
    hospital: 'Apollo Hospital, Chennai',
    doctor: 'Dr. Anand Mehta',
    date: '12 Feb 2026',
    patient: 'Self',
    tags: ['Blood', 'Routine'],
    icon: Icons.science_outlined,
    color: Color(0xFF009688),
  ),
  VaultRecord(
    type: 'Prescription',
    title: 'Cardiology Follow-up',
    hospital: 'Dr. Kapoor Clinic',
    doctor: 'Dr. Rahul Kapoor',
    date: '8 Feb 2026',
    patient: 'Self',
    tags: ['Heart', 'Medication'],
    icon: Icons.medication_outlined,
    color: Color(0xFF3B82F6),
  ),
  VaultRecord(
    type: 'Imaging',
    title: 'Chest X-Ray (PA View)',
    hospital: 'Max Diagnostics',
    doctor: 'Dr. Priya Nair',
    date: '5 Feb 2026',
    patient: 'Self',
    tags: ['Chest', 'Radiology'],
    icon: Icons.image_outlined,
    color: Color(0xFF8B5CF6),
  ),
  VaultRecord(
    type: 'Discharge Summary',
    title: 'Post Appendectomy Discharge',
    hospital: 'Fortis Hospital',
    doctor: 'Dr. S. Kumar',
    date: '20 Jan 2026',
    patient: 'Self',
    tags: ['Surgery', 'Emergency'],
    icon: Icons.description_outlined,
    color: Color(0xFFF59E0B),
  ),
  VaultRecord(
    type: 'Lab Report',
    title: 'Thyroid Profile (T3/T4/TSH)',
    hospital: 'SRL Diagnostics',
    doctor: 'Dr. Anand Mehta',
    date: '15 Jan 2026',
    patient: 'Amma',
    tags: ['Thyroid', 'Routine'],
    icon: Icons.science_outlined,
    color: Color(0xFF009688),
  ),
];
