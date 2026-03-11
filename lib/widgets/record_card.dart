import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/health_record.dart';
import '../theme/app_theme.dart';

class RecordCard extends StatelessWidget {
  final HealthRecord record;
  final VoidCallback? onTap;

  const RecordCard({
    super.key,
    required this.record,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');
    final documentColor = AppTheme.getDocumentTypeColor(record.recordType);
    final documentIcon = AppTheme.getDocumentTypeIcon(record.recordType);
    
    // Create a lighter version of the document color for the background
    final backgroundColor = Color.lerp(documentColor, Colors.white, 0.92);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Document type icon with colored background
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    documentIcon,
                    color: documentColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and chevron
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              record.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.foreground,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: AppTheme.mutedForeground,
                          ),
                        ],
                      ),
                      
                      // Notes preview if available
                      if (record.notes != null && record.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          record.notes!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.mutedForeground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      const SizedBox(height: 8),
                      
                      // Record type badge and date
                      Row(
                        children: [
                          // Date
                          Text(
                            dateFormat.format(record.recordDate),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.mutedForeground,
                            ),
                          ),
                          
                          // Dot separator
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '•',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.mutedForeground,
                              ),
                            ),
                          ),
                          
                          // Record type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.muted,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              record.recordType,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.mutedForeground,
                              ),
                            ),
                          ),
                          
                          // File info if available
                          if (record.fileName != null && record.fileSize != null) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '•',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.mutedForeground,
                                ),
                              ),
                            ),
                            Text(
                              _formatFileSize(record.fileSize!),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.mutedForeground,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
