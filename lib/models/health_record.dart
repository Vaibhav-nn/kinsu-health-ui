class HealthRecord {
  final String id;
  final String recordType;
  final DateTime recordDate;
  final String title;
  final String? notes;
  final String? fileName;
  final String? fileUrl;
  final int? fileSize;
  final DateTime? fileUploadedAt;

  HealthRecord({
    required this.id,
    required this.recordType,
    required this.recordDate,
    required this.title,
    this.notes,
    this.fileName,
    this.fileUrl,
    this.fileSize,
    this.fileUploadedAt,
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      id: json['id'].toString(),
      recordType: json['record_type'] as String,
      recordDate: DateTime.parse(json['record_date'] as String),
      title: json['title'] as String,
      notes: json['notes'] as String?,
      fileName: json['file_name'] as String?,
      fileUrl: json['file_url'] as String?,
      fileSize: json['file_size'] as int?,
      fileUploadedAt: json['file_uploaded_at'] != null
          ? DateTime.parse(json['file_uploaded_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'record_type': recordType,
      'record_date': recordDate.toIso8601String().split('T')[0],
      'title': title,
      'notes': notes,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_size': fileSize,
      'file_uploaded_at': fileUploadedAt?.toIso8601String(),
    };
  }

  String get fileExtension {
    if (fileName == null) return '';
    final parts = fileName!.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  bool get isPdf => fileExtension == 'pdf';
  bool get isImage => ['jpg', 'jpeg', 'png'].contains(fileExtension);
}
