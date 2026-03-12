class AiSummaryCard {
  final String title;
  final String badge;
  final bool warning;
  final String summary;
  final String action;
  final List<String> sources;

  const AiSummaryCard({
    required this.title,
    required this.badge,
    required this.warning,
    required this.summary,
    required this.action,
    required this.sources,
  });
}

const aiSummaryCards = <AiSummaryCard>[
  AiSummaryCard(
    title: 'Blood Sugar Management',
    badge: 'Needs Review',
    warning: true,
    summary:
        'Fasting blood sugar has been trending upward over the past 4 weeks (avg 140 mg/dL). HbA1c at 6.8% indicates pre-diabetic range.',
    action:
        'Consider discussing with Dr. Reddy about possible medication adjustment.',
    sources: [
      'CBC from Apollo Hospital · 12 Feb 2026',
      'Blood Sugar Readings (7 days)'
    ],
  ),
  AiSummaryCard(
    title: 'Blood Pressure Overview',
    badge: 'Grounded',
    warning: false,
    summary:
        'Blood pressure readings have improved over the past month (128/84 avg). Current treatment appears effective.',
    action: 'Continue regimen and follow next check-up in 4 weeks.',
    sources: ['BP Readings (30 days)', 'Dr. Kapoor Cardiology Rx · 8 Feb 2026'],
  ),
  AiSummaryCard(
    title: 'Vitamin D Status',
    badge: 'Grounded',
    warning: false,
    summary:
        'Vitamin D supplementation was prescribed 3 months ago. No follow-up test was logged yet.',
    action: 'Schedule a Vitamin D level test in your next lab cycle.',
    sources: ['Prescription · Nov 2025'],
  ),
];
