import 'package:amar_uddokta/uddoktaa/models/chat_message.dart';
import 'package:amar_uddokta/uddoktaa/widgets/background_container.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(message: text, isUser: true));
      _messages.add(ChatMessage(
          message: "ধন্যবাদ! আমরা আপনার বার্তা পেয়েছি।", isUser: false));
    });

    _controller.clear();
  }

  Widget _buildMessage(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: msg.isUser ? Colors.deepPurple[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(msg.message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('লাইভ চ্যাট'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) =>
                    _buildMessage(_messages[_messages.length - 1 - index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'বার্তা লিখুন...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.deepPurple),
                    onPressed: () => _sendMessage(_controller.text),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
