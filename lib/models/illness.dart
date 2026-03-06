/// Data models for Illness Episodes — matches backend Pydantic schemas.

class IllnessDetail {
  final int? id;
  final String detailType;
  final String content;
  final DateTime recordedAt;

  IllnessDetail({
    this.id,
    required this.detailType,
    required this.content,
    required this.recordedAt,
  });

  factory IllnessDetail.fromJson(Map<String, dynamic> json) => IllnessDetail(
        id: json['id'],
        detailType: json['detail_type'],
        content: json['content'],
        recordedAt: DateTime.parse(json['recorded_at']),
      );

  Map<String, dynamic> toJson() => {
        'detail_type': detailType,
        'content': content,
        'recorded_at': recordedAt.toIso8601String(),
      };
}

class IllnessEpisode {
  final int? id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<IllnessDetail> details;

  IllnessEpisode({
    this.id,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
    this.details = const [],
  });

  factory IllnessEpisode.fromJson(Map<String, dynamic> json) => IllnessEpisode(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        startDate: DateTime.parse(json['start_date']),
        endDate:
            json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
        status: json['status'] ?? 'active',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
        details: json['details'] != null
            ? (json['details'] as List)
                .map((e) => IllnessDetail.fromJson(e))
                .toList()
            : [],
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'start_date':
            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
        'end_date': endDate != null
            ? '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}'
            : null,
        'status': status,
      };
}
