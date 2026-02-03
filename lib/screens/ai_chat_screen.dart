import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/zhipu_chat_service.dart';
import '../widgets/gradient_bubbles_background.dart';
import 'voice_call_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

const String _welcomeMessage =
    'Hi there! I\'m your music guide. I can help you with anything about music—songwriting, production, genres, instruments, or recommendations. What would you like to know?';

const List<String> _presetQuestions = [
  'How do I get started with writing a song?',
  'What are some tips for music production?',
  'Can you recommend some music genres to explore?',
];

class _AiChatScreenState extends State<AiChatScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;

  Future<void> _sendWithText(String text) async {
    if (text.trim().isEmpty || _loading) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text.trim()});
      _loading = true;
    });
    _scrollToBottom();
    final history = _messages.map((m) => {'role': m['role']!, 'content': m['content']!}).toList();
    final reply = await ZhipuChatService.shared.sendChat(history);
    if (!mounted) return;
    setState(() {
      _messages.add({
        'role': 'assistant',
        'content': reply ?? 'Sorry, something went wrong. Please try again.',
      });
      _loading = false;
    });
    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    _controller.clear();
    await _sendWithText(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBubblesBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'AI Chat',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          actions: [
            IconButton(
              icon: Image.asset(
                'assets/icon_video_call.webp',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.call, color: Colors.white, size: 26),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const VoiceCallScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: 8,
                ),
                children: _messages.isEmpty && !_loading
                    ? [
                        _buildAssistantBubble(context, _welcomeMessage),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.only(left: 46),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _presetQuestions.map((q) {
                              return Material(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  onTap: () => _sendWithText(q),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Text(
                                      q,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ]
                    : [
                        ...List.generate(
                          _messages.length + (_loading ? 1 : 0),
                          (index) {
                            if (index == _messages.length) {
                              return _buildAssistantBubble(context, '...');
                            }
                            final m = _messages[index];
                            final isUser = m['role'] == 'user';
                            return isUser
                                ? _buildUserBubble(m['content']!)
                                : _buildAssistantBubble(context, m['content']!);
                          },
                        ),
                      ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.paddingOf(context).bottom + 8,
              ),
              color: Colors.transparent,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      maxLines: 4,
                      minLines: 1,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _loading ? null : _send,
                      borderRadius: BorderRadius.circular(24),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.send, color: Colors.white),
                      ),
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

  Widget _buildUserBubble(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: Radius.zero,
                ),
              ),
              child: Text(
                content,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantBubble(BuildContext context, String content) {
    final canCopy = content != '...';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            backgroundImage: const AssetImage('assets/applogo.png'),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.zero,
                  bottomRight: const Radius.circular(16),
                ),
              ),
              child: Text(
                content,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
          if (canCopy) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.copy,
                size: 20,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ],
      ),
    );
  }
}
