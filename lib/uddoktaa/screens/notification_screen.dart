import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('notifications')
            .stream(primaryKey: ['id'])
            .order('createdAt', ascending: false)
            .execute()
            .map((data) => data as List<Map<String, dynamic>>),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No notifications found.'));
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification;
              final message = data['message'] as String;
              final imageUrl = data['imageUrl'] as String?;
              final timestamp = DateTime.parse(data['createdAt']);

              return Card(
                margin: const EdgeInsets.all(8.0),
                elevation: 4.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Image.network(
                            imageUrl,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image,
                                    size: 40, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '${timestamp.toLocal().day}/${timestamp.toLocal().month}/${timestamp.toLocal().year} ${timestamp.toLocal().hour}:${timestamp.toLocal().minute}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
