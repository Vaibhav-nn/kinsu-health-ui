class VaultConnectedService {
  final int id;
  final String providerName;
  final String providerType;
  final String status;
  final int recordCount;
  final DateTime? syncedAt;

  const VaultConnectedService({
    required this.id,
    required this.providerName,
    required this.providerType,
    required this.status,
    required this.recordCount,
    required this.syncedAt,
  });

  factory VaultConnectedService.fromJson(Map<String, dynamic> json) {
    return VaultConnectedService(
      id: (json['id'] ?? 0) as int,
      providerName: (json['provider_name'] ?? '') as String,
      providerType: (json['provider_type'] ?? 'hospital') as String,
      status: (json['status'] ?? 'pending') as String,
      recordCount: (json['record_count'] ?? 0) as int,
      syncedAt: json['synced_at'] != null
          ? DateTime.tryParse(json['synced_at'].toString())
          : null,
    );
  }
}

class VaultLabTrendPoint {
  final DateTime observedOn;
  final double value;

  const VaultLabTrendPoint({
    required this.observedOn,
    required this.value,
  });

  factory VaultLabTrendPoint.fromJson(Map<String, dynamic> json) {
    return VaultLabTrendPoint(
      observedOn: DateTime.parse(json['observed_on'] as String),
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }
}

class VaultLabTrendHistoryItem {
  final DateTime observedOn;
  final double value;
  final String unit;

  const VaultLabTrendHistoryItem({
    required this.observedOn,
    required this.value,
    required this.unit,
  });

  factory VaultLabTrendHistoryItem.fromJson(Map<String, dynamic> json) {
    return VaultLabTrendHistoryItem(
      observedOn: DateTime.parse(json['observed_on'] as String),
      value: (json['value'] as num?)?.toDouble() ?? 0,
      unit: (json['unit'] ?? '') as String,
    );
  }
}

class VaultLabTrend {
  final String parameterKey;
  final String parameterLabel;
  final String unit;
  final double? latestValue;
  final String? status;
  final List<VaultLabTrendPoint> dataPoints;
  final List<VaultLabTrendHistoryItem> history;

  const VaultLabTrend({
    required this.parameterKey,
    required this.parameterLabel,
    required this.unit,
    required this.latestValue,
    required this.status,
    required this.dataPoints,
    required this.history,
  });

  factory VaultLabTrend.fromJson(Map<String, dynamic> json) {
    return VaultLabTrend(
      parameterKey: (json['parameter_key'] ?? '') as String,
      parameterLabel: (json['parameter_label'] ?? '') as String,
      unit: (json['unit'] ?? '') as String,
      latestValue: (json['latest_value'] as num?)?.toDouble(),
      status: json['status'] as String?,
      dataPoints: (json['data_points'] as List<dynamic>? ?? const [])
          .map((item) =>
              VaultLabTrendPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
      history: (json['history'] as List<dynamic>? ?? const [])
          .map((item) =>
              VaultLabTrendHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
