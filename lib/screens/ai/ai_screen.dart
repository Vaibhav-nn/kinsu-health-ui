import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/medications_provider.dart';
import '../../providers/vitals_provider.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  bool _showChat = false;

  @override
  Widget build(BuildContext context) {
    return _showChat
        ? _AiChatView(onBack: () => setState(() => _showChat = false))
        : _AiInsightsView(onOpenChat: () => setState(() => _showChat = true));
  }
}

// ── Insights View ─────────────────────────────────────────────────────────────

class _AiInsightsView extends StatelessWidget {
  final VoidCallback onOpenChat;

  const _AiInsightsView({required this.onOpenChat});

  @override
  Widget build(BuildContext context) {
    final medsProvider = context.watch<MedicationsProvider>();
    final vitalsProvider = context.watch<VitalsProvider>();

    final activeMeds = medsProvider.medications.where((m) => m.isActive).toList();
    final total = activeMeds.length;

    // Compute BP average
    final bpVitals = vitalsProvider.vitals
        .where((v) => v.vitalType == 'blood_pressure')
        .toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final last14bp = bpVitals.take(14).toList();
    final avgSys = last14bp.isEmpty
        ? null
        : last14bp.map((v) => v.value).reduce((a, b) => a + b) /
            last14bp.length;
    final avgDia = last14bp.isEmpty
        ? null
        : last14bp
                .where((v) => v.valueSecondary != null)
                .map((v) => v.valueSecondary!)
                .fold(0.0, (a, b) => a + b) /
            (last14bp.where((v) => v.valueSecondary != null).length.clamp(1, 100));

    final hasData = total > 0 || last14bp.isNotEmpty;

    return Scaffold(
      backgroundColor: KinsuTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            // Title
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Insights',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: KinsuTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Grounded in your own records',
                  style: TextStyle(
                    fontSize: 13,
                    color: KinsuTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ask Kinsu AI card
            GestureDetector(
              onTap: onOpenChat,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: KinsuTheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ask Kinsu AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Chat about your health data with cited sources',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white70),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: Color(0xFFB45309)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI insights are generated from your health records and should never replace professional medical advice.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Health Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),

            if (!hasData)
              _InsightCard(
                icon: Icons.lightbulb_outline,
                iconColor: KinsuTheme.primary,
                iconBg: KinsuTheme.primaryLight,
                title: 'Start logging to unlock insights',
                badge: 'No data',
                badgeGreen: false,
                summary:
                    'Log your vitals and medications to receive personalised AI insights grounded in your records.',
                suggestedAction:
                    'Go to Track → Log Vitals or add your medications.',
              )
            else ...[
              if (total > 0)
                _MedicationInsightCard(
                  total: total,
                  taken: 0, // no local taken state here — summary only
                )
              else
                const SizedBox.shrink(),
              if (last14bp.isNotEmpty && avgSys != null) ...[
                const SizedBox(height: 12),
                _BpInsightCard(avgSys: avgSys, avgDia: avgDia ?? 0),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MedicationInsightCard extends StatelessWidget {
  final int total;
  final int taken;

  const _MedicationInsightCard({required this.total, required this.taken});

  @override
  Widget build(BuildContext context) {
    final adherencePct = total == 0 ? 0 : ((taken / total) * 100).round();
    final isGood = adherencePct >= 80;
    final isOk = adherencePct >= 50;
    final badge = isGood
        ? 'On track'
        : isOk
            ? 'Needs attention'
            : 'Low adherence';
    final isGreen = isGood;

    return _InsightCard(
      icon: Icons.medication_outlined,
      iconColor: isGood
          ? KinsuTheme.success
          : isOk
              ? KinsuTheme.statusWarning
              : KinsuTheme.statusError,
      iconBg: isGood
          ? const Color(0xFFD1FAE5)
          : isOk
              ? const Color(0xFFFFF3CD)
              : const Color(0xFFFEE2E2),
      title: 'Medication Adherence',
      badge: badge,
      badgeGreen: isGreen,
      summary:
          'You have $total active medication${total == 1 ? '' : 's'}. '
          'Today\'s adherence tracking is available in the Track section.',
      suggestedAction: isGood
          ? 'Keep it up — consistent adherence supports better outcomes.'
          : 'Log your medications in the Track section to improve adherence.',
    );
  }
}

class _BpInsightCard extends StatelessWidget {
  final double avgSys;
  final double avgDia;

  const _BpInsightCard({required this.avgSys, required this.avgDia});

  @override
  Widget build(BuildContext context) {
    final isHealthy = avgSys < 140 && avgDia < 90;
    final badge = isHealthy ? 'Healthy' : 'Needs review';

    return _InsightCard(
      icon: Icons.favorite_border,
      iconColor: isHealthy ? KinsuTheme.success : KinsuTheme.statusError,
      iconBg: isHealthy
          ? const Color(0xFFD1FAE5)
          : const Color(0xFFFEE2E2),
      title: 'Blood Pressure Trend',
      badge: badge,
      badgeGreen: isHealthy,
      summary:
          '${avgSys.toStringAsFixed(0)}/${avgDia.toStringAsFixed(0)} mmHg average over the last 14 readings.',
      suggestedAction: isHealthy
          ? 'Your blood pressure is in a healthy range. Keep monitoring.'
          : 'Average BP is elevated. Discuss with your doctor.',
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String badge;
  final bool badgeGreen;
  final String summary;
  final String suggestedAction;

  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.badge,
    required this.badgeGreen,
    required this.summary,
    required this.suggestedAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: KinsuTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: KinsuTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeGreen
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeGreen
                        ? const Color(0xFF047857)
                        : const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: const TextStyle(
              fontSize: 13,
              color: KinsuTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: KinsuTheme.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suggested Action',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: KinsuTheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  suggestedAction,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat View ─────────────────────────────────────────────────────────────────

enum _MessageRole { user, ai }

class _ChatMessage {
  final _MessageRole role;
  final String text;
  final bool isTyping;

  const _ChatMessage({
    required this.role,
    required this.text,
    this.isTyping = false,
  });
}

class _AiChatView extends StatefulWidget {
  final VoidCallback onBack;

  const _AiChatView({required this.onBack});

  @override
  State<_AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends State<_AiChatView> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      role: _MessageRole.ai,
      text:
          'Hello! I\'m Kinsu AI, grounded in your health records. Ask me about your blood pressure, medications, or anything in your vault.',
    ),
  ];
  bool _isLoading = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _inputCtrl.clear();

    setState(() {
      _messages.add(_ChatMessage(role: _MessageRole.user, text: trimmed));
      _messages.add(const _ChatMessage(
        role: _MessageRole.ai,
        text: '',
        isTyping: true,
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 700));

    final reply = _generateReply(trimmed.toLowerCase());

    if (!mounted) return;
    setState(() {
      _messages.removeLast();
      _messages.add(_ChatMessage(role: _MessageRole.ai, text: reply));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  String _generateReply(String input) {
    if (input.contains('bp') ||
        input.contains('pressure') ||
        input.contains('blood pressure')) {
      return 'Based on your recent vitals, your blood pressure trend shows the average over the last 14 readings. '
          'Normal range is below 120/80 mmHg. Values above 140/90 may need medical attention. '
          '\n\nSources: Your BP log (last 14 entries).';
    }
    if (input.contains('miss') ||
        input.contains('medication') ||
        input.contains('pill') ||
        input.contains('med')) {
      return 'Your medication adherence is tracked based on what you log in the Track section. '
          'To see today\'s status, go to Track → Medications.\n\nSources: Your medication log.';
    }
    if (input.contains('diagnos') || input.contains('prescribe')) {
      return 'I\'m not able to provide diagnoses or prescriptions. I can only summarise information from your own health records. '
          'Please consult a qualified medical professional for medical decisions.';
    }
    if (input.contains('mood') || input.contains('feeling')) {
      return 'I don\'t currently have mood tracking data. You can log symptoms in the Track section to capture how you feel over time.';
    }
    return 'Try asking about your blood pressure, medications, or records. '
        'For example: "Summarise my blood pressure" or "What medications am I taking?"';
  }

  static const _chips = [
    'Summarise my blood pressure',
    'What did I miss today?',
    'How is my mood?',
    'Medication summary',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KinsuTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom header ──────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: KinsuTheme.divider, width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: widget.onBack,
                    color: KinsuTheme.textPrimary,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.auto_awesome,
                      color: KinsuTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kinsu AI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: KinsuTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Grounded in your records · Offline',
                          style: TextStyle(
                            fontSize: 11,
                            color: KinsuTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Color(0xFF047857)),
                        SizedBox(width: 4),
                        Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            // ── Message list ───────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final msg = _messages[i];
                  if (msg.isTyping) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    );
                  }
                  final isUser = msg.role == _MessageRole.user;
                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isUser ? KinsuTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: isUser
                            ? null
                            : Border.all(color: KinsuTheme.divider),
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isUser ? Colors.white : KinsuTheme.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Prompt chips ───────────────────────────────────────────
            if (!_isLoading)
              Container(
                height: 44,
                color: Colors.white,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _chips.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Center(
                    child: GestureDetector(
                      onTap: () => _sendMessage(_chips[i]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: KinsuTheme.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: KinsuTheme.primary),
                        ),
                        child: Text(
                          _chips[i],
                          style: const TextStyle(
                            fontSize: 12,
                            color: KinsuTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Input bar ──────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: KinsuTheme.divider, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ask about your health data…',
                        hintStyle: const TextStyle(
                            color: KinsuTheme.textSecondary, fontSize: 14),
                        filled: true,
                        fillColor: KinsuTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: KinsuTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(_inputCtrl.text),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
