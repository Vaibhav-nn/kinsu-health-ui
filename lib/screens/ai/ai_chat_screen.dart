import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'ai_refusal_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      isUser: true,
      text: 'Can you summarize my recent blood reports?',
    ),
    const _ChatMessage(
      isUser: false,
      text:
          'From your latest CBC report: Hemoglobin, RBC, WBC, and Platelets are within normal range. HbA1c is 6.8%, which indicates pre-diabetic range.\n\nSources: CBC Apollo Hospital (12 Feb 2026), blood sugar logs.',
      badge: 'Grounded',
    ),
  ];
  bool _typing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: text));
      _controller.clear();
      _typing = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    final lower = text.toLowerCase();
    final unsafe = lower.contains('diagnos') ||
        lower.contains('increase') && lower.contains('dose');
    if (unsafe) {
      setState(() => _typing = false);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AiRefusalScreen()),
      );
      return;
    }

    setState(() {
      _typing = false;
      _messages.add(
        const _ChatMessage(
          isUser: false,
          text:
              'Based on your records, I can share trends and citations. For treatment decisions, please consult your doctor.',
          badge: 'Grounded',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kinsu AI Chat'),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFFB45309), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI responses are grounded in your records and are not medical diagnosis.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length + (_typing ? 1 : 0),
              itemBuilder: (context, index) {
                if (_typing && index == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Typing...'),
                    ),
                  );
                }

                final msg = _messages[index];
                if (msg.isUser) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: KinsuTheme.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        msg.text,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.all(12),
                  decoration: KinsuTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (msg.badge != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F9F3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg.badge!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ),
                      Text(msg.text),
                    ],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Ask about your health...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final bool isUser;
  final String text;
  final String? badge;

  const _ChatMessage({required this.isUser, required this.text, this.badge});
}
