import '../models/prescription.dart';
import '../models/next_dose.dart';

class MockData {
  static List<Prescription> recentPrescriptions = [
    Prescription(
      id: '1',
      name: 'Lisinopril 10mg',
      doctor: 'Dr. Sarah Chen',
      openedAt: DateTime.now().subtract(const Duration(hours: 2)),
      status: 'Active',
    ),
    Prescription(
      id: '2',
      name: 'Metformin 500mg',
      doctor: 'Dr. James Wilson',
      openedAt: DateTime.now().subtract(const Duration(days: 1)),
      status: 'Active',
    ),
    Prescription(
      id: '3',
      name: 'Amlodipine 5mg',
      doctor: 'Dr. Sarah Chen',
      openedAt: DateTime.now().subtract(const Duration(days: 2)),
      status: 'Active',
    ),
  ];

  static List<NextDose> nextDoses = [
    NextDose(
      id: '1',
      medicationName: 'Lisinopril 10mg',
      scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      dosage: '1 tablet',
      isOverdue: false,
    ),
    NextDose(
      id: '2',
      medicationName: 'Metformin 500mg',
      scheduledAt: DateTime.now().add(const Duration(hours: 6)),
      dosage: '1 tablet with breakfast',
      isOverdue: false,
    ),
    NextDose(
      id: '3',
      medicationName: 'Vitamin D3',
      scheduledAt: DateTime.now().subtract(const Duration(hours: 1)),
      dosage: '1 softgel',
      isOverdue: true,
    ),
  ];
}
