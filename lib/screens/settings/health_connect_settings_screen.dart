import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/health_sync_provider.dart';

/// Phase 3 — Health Connect settings screen.
///
/// Surfaces:
///   • Availability banner (unavailable / needs-update / ready).
///   • Permission request card.
///   • Write-back toggle (mirror Kinsu data → HC).
///   • Import buttons (last 30 / 90 / 180 days).
///   • Last-sync timestamp and import count.
///   • Debug row to clear the sync registry.
class HealthConnectSettingsScreen extends StatelessWidget {
  const HealthConnectSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Connect'),
      ),
      body: Consumer<HealthSyncProvider>(
        builder: (context, hsp, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _AvailabilityBanner(hsp: hsp),
              if (hsp.isAvailable) ...[
                const SizedBox(height: 4),
                _PermissionsCard(hsp: hsp),
                const SizedBox(height: 4),
                _WriteBackCard(hsp: hsp),
                const SizedBox(height: 4),
                _ImportCard(hsp: hsp),
                const SizedBox(height: 4),
                _SyncStatusCard(hsp: hsp),
                const SizedBox(height: 16),
                _DebugSection(hsp: hsp),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── Availability banner ───────────────────────────────────────────────────────

class _AvailabilityBanner extends StatelessWidget {
  final HealthSyncProvider hsp;
  const _AvailabilityBanner({required this.hsp});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (hsp.isAvailable) {
      return const _BannerTile(
        icon: Icons.check_circle_outline,
        color: Colors.green,
        title: 'Health Connect is available',
        subtitle: 'Your device supports Health Connect integration.',
      );
    }

    return _BannerTile(
      icon: Icons.warning_amber_rounded,
      color: colorScheme.error,
      title: 'Health Connect unavailable',
      subtitle:
          'Install or update the Health Connect app from the Play Store to '
          'enable this feature.',
    );
  }
}

// ── Permissions card ──────────────────────────────────────────────────────────

class _PermissionsCard extends StatelessWidget {
  final HealthSyncProvider hsp;
  const _PermissionsCard({required this.hsp});

  @override
  Widget build(BuildContext context) {
    final hasPerms = hsp.status != HCSyncStatus.noPermission &&
        hsp.status != HCSyncStatus.unavailable;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasPerms ? Icons.lock_open : Icons.lock_outline,
                  color: hasPerms ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasPerms ? 'Permissions granted' : 'Permissions required',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasPerms
                  ? 'Kinsu can read and write health data from Health Connect.'
                  : 'Grant permissions so Kinsu can sync vitals and workouts '
                      'with Health Connect.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (!hasPerms) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => hsp.requestPermissions(),
                icon: const Icon(Icons.security),
                label: const Text('Grant permissions'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Write-back toggle ─────────────────────────────────────────────────────────

class _WriteBackCard extends StatelessWidget {
  final HealthSyncProvider hsp;
  const _WriteBackCard({required this.hsp});

  @override
  Widget build(BuildContext context) {
    final permOk = hsp.status != HCSyncStatus.noPermission &&
        hsp.status != HCSyncStatus.unavailable;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SwitchListTile(
        secondary: const Icon(Icons.sync_alt),
        title: const Text('Mirror to Health Connect'),
        subtitle: const Text(
          'Vitals and workouts logged in Kinsu are also written to Health '
          'Connect so other apps can see them.',
        ),
        value: hsp.writeBackEnabled,
        onChanged: permOk ? (v) => hsp.toggleWriteBack(v) : null,
      ),
    );
  }
}

// ── Import card ───────────────────────────────────────────────────────────────

class _ImportCard extends StatelessWidget {
  final HealthSyncProvider hsp;
  const _ImportCard({required this.hsp});

  @override
  Widget build(BuildContext context) {
    final isSyncing = hsp.status == HCSyncStatus.syncing;
    final permOk = hsp.status != HCSyncStatus.noPermission &&
        hsp.status != HCSyncStatus.unavailable;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.download_rounded),
                const SizedBox(width: 12),
                Text(
                  'Import from Health Connect',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pull your health data from Health Connect into Kinsu. '
              'Already-imported records are skipped automatically.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (isSyncing)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Importing…'),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ImportButton(
                    label: 'Last 30 days',
                    days: 30,
                    enabled: permOk,
                    hsp: hsp,
                  ),
                  _ImportButton(
                    label: 'Last 90 days',
                    days: 90,
                    enabled: permOk,
                    hsp: hsp,
                  ),
                  _ImportButton(
                    label: 'Last 180 days',
                    days: 180,
                    enabled: permOk,
                    hsp: hsp,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ImportButton extends StatelessWidget {
  final String label;
  final int days;
  final bool enabled;
  final HealthSyncProvider hsp;

  const _ImportButton({
    required this.label,
    required this.days,
    required this.enabled,
    required this.hsp,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? () => hsp.importFromHC(days: days) : null,
      child: Text(label),
    );
  }
}

// ── Sync status card ──────────────────────────────────────────────────────────

class _SyncStatusCard extends StatelessWidget {
  final HealthSyncProvider hsp;
  const _SyncStatusCard({required this.hsp});

  @override
  Widget build(BuildContext context) {
    final lastSync = hsp.lastSyncAt;
    final fmt = DateFormat('d MMM y, HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history),
                const SizedBox(width: 12),
                Text(
                  'Sync status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StatusRow(
              label: 'Last sync',
              value: lastSync != null ? fmt.format(lastSync) : 'Never',
            ),
            if (hsp.status == HCSyncStatus.done)
              _StatusRow(
                label: 'Records imported',
                value: '${hsp.lastImportCount}',
              ),
            if (hsp.status == HCSyncStatus.error && hsp.lastError != null)
              _StatusRow(
                label: 'Last error',
                value: hsp.lastError!,
                isError: true,
              ),
            _StatusRow(
              label: 'Registry size',
              value: '${hsp.registryCount} UUIDs tracked',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isError;

  const _StatusRow({
    required this.label,
    required this.value,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isError ? Theme.of(context).colorScheme.error : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Debug section ─────────────────────────────────────────────────────────────

class _DebugSection extends StatelessWidget {
  final HealthSyncProvider hsp;
  const _DebugSection({required this.hsp});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'Developer',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Clear sync registry'),
            subtitle: Text(
              '${hsp.registryCount} UUIDs — forces re-evaluation on next import',
            ),
            trailing: TextButton(
              onPressed: () => _confirmClear(context),
              child: const Text('Clear'),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear sync registry?'),
        content: const Text(
          'All tracked Health Connect UUIDs will be removed. '
          'The next import will re-evaluate every record in the selected '
          'date range. Duplicate records may be created if the backend '
          'doesn\'t deduplicate by timestamp.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              hsp.clearRegistry();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

// ── Shared banner tile ────────────────────────────────────────────────────────

class _BannerTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _BannerTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: color,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
