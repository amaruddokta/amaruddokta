import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _supabase.auth.currentUser;
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty && _user != null) {
      // Also save the user's name to the chat document for the admin panel
      await _supabase.from('chats').upsert({
        'id': _user!.id,
        'userName': _user!.userMetadata?['name'] ?? 'No Name',
      });

      await _supabase.from('messages').insert({
        'chat_id': _user!.id,
        'text': _messageController.text,
        'senderId': _user!.id,
      });
      _messageController.clear();
    }
  }

  void _editMessage(Map<String, dynamic> message) {
    final TextEditingController editController =
        TextEditingController(text: message['text']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: editController,
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () async {
              if (editController.text.isNotEmpty) {
                await _supabase.from('messages').update(
                    {'text': editController.text}).eq('id', message['id']);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _deleteMessage(Map<String, dynamic> message) {
    _supabase.from('messages').delete().eq('id', message['id']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: _user == null
          ? const Center(
              child: Text('Please log in to use the chat.'),
            )
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _supabase
                        .from('messages')
                        .stream(primaryKey: ['id'])
                        .eq('chat_id', _user!.id)
                        .order('created_at', ascending: false),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      final messages = snapshot.data!;
                      return ListView.builder(
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message['senderId'] == _user!.id;
                          return GestureDetector(
                            onLongPress: () {
                              if (isMe) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    actions: [
                                      TextButton(
                                        child: const Text('Edit'),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _editMessage(message);
                                        },
                                      ),
                                      TextButton(
                                        child: const Text('Delete'),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteMessage(message);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            child: ListTile(
                              title: Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color:
                                        isMe ? Colors.blue : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    message['text'],
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Enter your message...',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
