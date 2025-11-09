import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amar_uddokta/uddoktaa/controllers/AboutController.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AboutController aboutController = Get.put(AboutController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Our Team'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Obx(() {
        if (aboutController.aboutList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No team members found.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: aboutController.aboutList.length,
          itemBuilder: (context, index) {
            final data = aboutController.aboutList[index];
            final manTitle = data['manTitle'] as String? ?? 'Name';
            final manSubtitle = data['manSubtitle'] as String? ?? 'Position';
            final manRole = data['manRole'] as String? ?? 'Role';
            final manDescription = data['manDescription'] as String? ?? 'Bio';
            final manImageUrl = data['manImageUrl'] as String?;

            return Card(
              margin: const EdgeInsets.only(bottom: 20.0),
              elevation: 8,
              shadowColor: Colors.deepPurple.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Display order number
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Profile image
                    if (manImageUrl != null && manImageUrl.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 70,
                          backgroundImage: NetworkImage(manImageUrl),
                          onBackgroundImageError: (_, __) => const Icon(
                            Icons.person,
                            size: 70,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.deepPurple.withOpacity(0.1),
                        ),
                        child: const CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.transparent,
                          child: Icon(
                            Icons.person,
                            size: 70,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Title
                    Text(
                      manTitle,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      manSubtitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.deepPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.deepPurple),
                    const SizedBox(height: 16),
                    // Role
                    _buildInfoRow(Icons.work, 'Role', manRole),
                    const SizedBox(height: 16),
                    // Description section
                    const Text(
                      'Bio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      manDescription,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple, size: 20),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
