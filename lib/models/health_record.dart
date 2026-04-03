class HealthRecord {
  final String id;
  final int? familyMemberId;
  final String recordType;
  final String? documentSubtype;
  final DateTime recordDate;
  final String title;
  final String? providerName;
  final List<String> tags;
  final String? notes;
  final String? fileName;
  final String? fileUrl;
  final int? fileSize;
  final DateTime? fileUploadedAt;

  HealthRecord({
    required this.id,
    required this.familyMemberId,
    required this.recordType,
    required this.documentSubtype,
    required this.recordDate,
    required this.title,
    required this.providerName,
    required this.tags,
    this.notes,
    this.fileName,
    this.fileUrl,
    this.fileSize,
    this.fileUploadedAt,
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      id: json['id'].toString(),
      familyMemberId: json['family_member_id'] as int?,
      recordType: (json['record_type'] ?? '') as String,
      documentSubtype: json['document_subtype'] as String?,
      recordDate: DateTime.parse(json['record_date'] as String),
      title: json['title'] as String,
      providerName: json['provider_name'] as String?,
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
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
      'family_member_id': familyMemberId,
      'record_type': recordType,
      'document_subtype': documentSubtype,
      'record_date': recordDate.toIso8601String().split('T')[0],
      'title': title,
      'provider_name': providerName,
      'tags': tags,
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
  bool get isImage => ['jpg', 'jpeg', 'png', 'webp'].contains(fileExtension);

  String get normalizedType => recordType.toLowerCase().replaceAll(' ', '_');

  String get displayRecordType {
    switch (normalizedType) {
      case 'lab_report':
        return 'Lab Report';
      case 'prescription':
        return 'Prescription';
      case 'imaging':
        return 'Imaging';
      case 'discharge_summary':
        return 'Discharge Summary';
      case 'handwritten_note':
        return 'Handwritten Note';
      default:
        final source = recordType.replaceAll('_', ' ').trim();
        if (source.isEmpty) return 'Record';
        return source
            .split(' ')
            .map(
              (part) => part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' ');
    }
  }

  String? get displayDocumentSubtype {
    final value = documentSubtype?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }
}
