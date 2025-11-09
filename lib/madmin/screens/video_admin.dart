import 'dart:io';

import 'package:amar_uddokta/uddoktaa/models/video_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'custom_button.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  File? _videoFile;

  Future<void> _pickVideo() async {
    final pickedFile =
        await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _compressAndUploadVideo() async {
    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a video first!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Compress video
      MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        _videoFile!.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (mediaInfo == null || mediaInfo.file == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video compression failed!')),
        );
        return;
      }

      File compressedVideo = mediaInfo.file!;

      // Upload to Supabase Storage
      final videoPath = 'videos/${DateTime.now().millisecondsSinceEpoch}.mp4';
      await _supabase.storage.from('videos').upload(
            videoPath,
            compressedVideo,
          );
      final String downloadUrl =
          _supabase.storage.from('videos').getPublicUrl(videoPath);

      // Add video to Supabase
      await _supabase.from('adminVideoss').insert({
        'adminurlvideos': downloadUrl,
        'timestamp': DateTime.now().toIso8601String(),
      });

      setState(() {
        _videoFile = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Video uploaded and added successfully!')),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading video: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Video Upload Section
            const Text(
              'Upload Video',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _videoFile != null
                ? Text('Selected: ${_videoFile!.path.split('/').last}')
                : const Text('No video selected'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CustomButton(
                  text: 'Pick Video',
                  onPressed: _pickVideo,
                  icon: Icons.video_library,
                ),
                CustomButton(
                  text: 'Upload Video',
                  onPressed: _compressAndUploadVideo,
                  icon: Icons.upload_file,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : const SizedBox.shrink(),
            const SizedBox(height: 20),
            const Text(
              'Added Videos:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _supabase.from('adminVideoss').stream(
                    primaryKey: ['id']).order('timestamp', ascending: false),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final videos = snapshot.data!;
                  return ListView.builder(
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final video = Video.fromMap(
                        videos[index],
                      );
                      return Card(
                        child: ListTile(
                          title: Text(video.link.isNotEmpty
                              ? 'Uploaded Video'
                              : 'Invalid Video'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.play_arrow),
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/user'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  final videoUrl = video.link;
                                  final videoPath = videoUrl
                                      .substring(videoUrl.indexOf('/o/') + 3);
                                  await _supabase.storage
                                      .from('videos')
                                      .remove([videoPath]);
                                  await _supabase
                                      .from('adminVideoss')
                                      .delete()
                                      .eq('id', video.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
