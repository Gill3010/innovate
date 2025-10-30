import 'package:flutter/material.dart';
import '../../ai/data/ai_service.dart';
import '../../../core/api_client.dart';

class CareerChatSheet extends StatefulWidget {
  const CareerChatSheet({super.key});

  @override
  State<CareerChatSheet> createState() => _CareerChatSheetState();
}

class _CareerChatSheetState extends State<CareerChatSheet> {
  final TextEditingController _ctrl = TextEditingController();
  final List<_ChatMsg> _messages = [];
  late final AiService _ai;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _ai = AiService(ApiClient());
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _messages.add(_ChatMsg(role: 'user', text: text));
      _ctrl.clear();
    });
    try {
      final reply = await _ai.careerChat(text);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMsg(role: 'assistant', text: reply));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error IA: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Asesor laboral IA', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final m = _messages[_messages.length - 1 - index];
                  final isUser = m.role == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(m.text),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(hintText: 'Escribe tu consulta...'),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
                  onPressed: _sending ? null : _send,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _ChatMsg {
  _ChatMsg({required this.role, required this.text});
  final String role;
  final String text;
}


