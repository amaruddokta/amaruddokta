import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class ImageUploader extends StatefulWidget {
  final Function(String? bunnyCdnUrl, String? supabaseStorageUrl)
      onImageUploaded;

  const ImageUploader({super.key, required this.onImageUploaded});

  @override
  _ImageUploaderState createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  File? _image;
  String? _bunnyCdnUrl;
  String? _supabaseStorageUrl;
  bool _isUploading = false;

  // BunnyCDN configuration
  final String storageZone = 'maa21';
  final String accessKey = '12e1e27e-0331-47ec-938f290ef9f9-5f4b-4fa5';
  final String pullZoneUrl = 'https://maa21.b-cdn.net';
  final String region = 'sg'; // Your region

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    setState(() {
      _isUploading = true;
      _bunnyCdnUrl = null;
      _supabaseStorageUrl = null;
    });

    try {
      if (_image != null) {
        // Upload to BunnyCDN
        String fileExtension = path.extension(_image!.path);
        if (fileExtension.isEmpty || fileExtension == '.') {
          fileExtension =
              '.jpg'; // Default to jpg if no extension or just a dot
        }
        final bunnyCdnFileName =
            'images/${DateTime.now().millisecondsSinceEpoch}$fileExtension';
        final bunnyCdnBytes = await _image!.readAsBytes();
        final bunnyCdnUrl =
            await _uploadToBunnyCDN(bunnyCdnBytes, bunnyCdnFileName);

        // Upload to Supabase Storage
        final supabaseStorageFileName =
            'images/${DateTime.now().millisecondsSinceEpoch}$fileExtension';
        final supabaseStorageUrl =
            await _uploadToSupabaseStorage(_image!, supabaseStorageFileName);

        setState(() {
          _bunnyCdnUrl = bunnyCdnUrl;
          _supabaseStorageUrl = supabaseStorageUrl;
        });

        widget.onImageUploaded(bunnyCdnUrl, supabaseStorageUrl);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Images uploaded successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Upload failed: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<String?> _uploadToBunnyCDN(
      Uint8List fileBytes, String fileName) async {
    try {
      final url = Uri.parse(
        'https://$region.storage.bunnycdn.com/$storageZone/$fileName',
      );
      final response = await http.put(
        url,
        headers: {
          'AccessKey': accessKey,
          'Content-Type': 'application/octet-stream',
        },
        body: fileBytes,
      );

      if (response.statusCode == 201) {
        return '$pullZoneUrl/$fileName';
      } else {
        debugPrint(
            'BunnyCDN Upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('BunnyCDN Upload error: $e');
      return null;
    }
  }

  Future<String?> _uploadToSupabaseStorage(File image, String fileName) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.storage.from('images').upload(fileName, image);
      final String publicUrl =
          supabase.storage.from('images').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('Supabase Storage upload error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_image != null)
          Image.file(
            _image!,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          )
        else
          const Text('No image selected'),
        ElevatedButton(
          onPressed: _isUploading ? null : _pickImage,
          child: Text(_isUploading ? 'Uploading...' : 'Select Image'),
        ),
        if (_bunnyCdnUrl != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'BunnyCDN URL: $_bunnyCdnUrl',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (_supabaseStorageUrl != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Supabase Storage URL: $_supabaseStorageUrl',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}
