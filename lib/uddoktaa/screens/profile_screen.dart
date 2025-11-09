import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;

import '../data/location_data.dart';
import '../models/user.dart' as MyUser;
import '../services/user_prefs.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  String? _division, _district, _upazila, _union;
  File? _imageFile;
  String? _profileImageUrl;
  String? _phone;
  String? _userId;
  String _referCode = '';
  double _referBalance = 0.0;

  final TextEditingController _wardCtrl = TextEditingController();
  final TextEditingController _houseCtrl = TextEditingController();
  final TextEditingController _roadCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userId = supabase_flutter.Supabase.instance.client.auth.currentUser?.id;
    if (_userId != null) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    final user = await UserPrefs.getUser();
    if (user != null && _userId != null) {
      _nameCtrl.text = user.name;
      _phone = user.phone;

      final response = await supabase_flutter.Supabase.instance.client
          .from('users')
          .select()
          .eq('uid', _userId!)
          .single();
      final data = response as Map<String, dynamic>;
      if (data != null) {
        _villageCtrl.text = data['village'] ?? '';
        _wardCtrl.text = data['ward'] ?? '';
        _houseCtrl.text = data['house'] ?? '';
        _roadCtrl.text = data['road'] ?? '';
        _division = data['division'];
        _district = data['district'];
        _upazila = data['upazila'];
        _union = data['union'];

        _referCode = data['refer_code'] ?? '';
        final dynamic balance = data['refer_balance'];
        if (balance is String) {
          _referBalance = double.tryParse(balance) ?? 0.0;
        } else if (balance is num) {
          _referBalance = balance.toDouble();
        } else {
          _referBalance = 0.0;
        }
      }

      if (data != null) {
        _profileImageUrl = data['imageUrl'];
      }

      if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
        // No need to set _imageFile, NetworkImage will handle it
      }

      setState(() {});
    }
  }

  Future<String?> _uploadImageToSupabaseStorage(
      File imageFile, String userEmail) async {
    try {
      if (!await imageFile.exists()) {
        debugPrint('File does not exist: ${imageFile.path}');
        return null;
      }

      String fileExtension = path.extension(imageFile.path);
      if (fileExtension.isEmpty || fileExtension == '.') {
        fileExtension = '.jpg';
      }

      final fileName =
          'profile1/${userEmail.replaceAll('.', '_')}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';

      final String publicUrl =
          await supabase_flutter.Supabase.instance.client.storage
              .from('profile_images') // Changed bucket name to 'profile_images'
              .upload(
                fileName,
                imageFile,
                fileOptions: const supabase_flutter.FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                  contentType: 'image/jpeg',
                ),
              );

      debugPrint('File uploaded successfully: $publicUrl');
      return publicUrl;
    } on supabase_flutter.StorageException catch (e) {
      debugPrint('Supabase Storage error: ${e.message}');
      Get.snackbar(
        'আপলোড ত্রুটি',
        'সুপাবেস স্টোরেজ ত্রুটি: ${e.message}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return null;
    } catch (e) {
      debugPrint('Upload error: $e');
      Get.snackbar(
        'আপলোড ত্রুটি',
        'ছবি আপলোড করার সময় একটি সমস্যা হয়েছে: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return null;
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
      final userEmail =
          supabase_flutter.Supabase.instance.client.auth.currentUser?.email;

      if (userEmail == null || userEmail.isEmpty) {
        Get.snackbar(
          'ত্রুটি',
          'ইমেইল ঠিকানা প্রয়োজন',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return;
      }

      final uploadedUrl =
          await _uploadImageToSupabaseStorage(_imageFile!, userEmail);

      if (uploadedUrl != null) {
        setState(() {
          _profileImageUrl = uploadedUrl;
        });
        Get.snackbar(
          'সফল',
          'ছবি আপলোড হয়েছে',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      } else {
        Get.snackbar(
          'ত্রুটি',
          'ছবি আপলোড ব্যর্থ হয়েছে',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_userId == null) {
      Get.snackbar(
        'ত্রুটি',
        'ব্যবহারকারী লগইন করা নেই।',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }
    await supabase_flutter.Supabase.instance.client.from('users').update({
      'name': _nameCtrl.text,
      'division': _division,
      'district': _district,
      'upazila': _upazila,
      'union': _union,
      'village': _villageCtrl.text,
      'ward': _wardCtrl.text,
      'house': _houseCtrl.text,
      'road': _roadCtrl.text,
      'imageUrl': _profileImageUrl,
    }).eq('uid', _userId!); // Changed 'id' to 'uid'

    final updatedUser = MyUser.User(
      uid: _userId!,
      name: _nameCtrl.text,
      phone: _phone ?? '',
      password: '', // Password is not managed here
      division: _division ?? '',
      district: _district ?? '',
      upazila: _upazila ?? '',
      village: _villageCtrl.text,
      imageUrl: _profileImageUrl,
    );
    await UserPrefs.saveUser(updatedUser);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('প্রোফাইল সফলভাবে আপডেট হয়েছে'),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }

  Future<void> _logout() async {
    await supabase_flutter.Supabase.instance.client.auth.signOut();
    await UserPrefs.clearUser();
    Get.offAllNamed('/register');
  }

  Future<void> _deleteAccount() async {
    if (_userId == null) {
      Get.snackbar(
        'ত্রুটি',
        'ব্যবহারকারী লগইন করা নেই।',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    final confirmDelete = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('অ্যাকাউন্ট ডিলিট করুন'),
        content: const Text(
            'আপনি কি নিশ্চিত যে আপনি আপনার অ্যাকাউন্ট ডিলিট করতে চান? এই প্রক্রিয়াটি অপরিবর্তনীয়।'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('হ্যাঁ, ডিলিট করুন'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        // Delete profile image from Supabase Storage
        if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
          final fileName = path.basename(_profileImageUrl!);
          await supabase_flutter.Supabase.instance.client.storage
              .from('profile_images') // Changed bucket name to 'profile_images'
              .remove([fileName]);
        }

        // Delete user document from Supabase
        await supabase_flutter.Supabase.instance.client
            .from('users')
            .delete()
            .eq('uid', _userId!); // Changed 'id' to 'uid'

        // Delete Supabase Authentication user (client-side deletion is not directly available, usually handled via admin API or server-side function)
        // For now, we will clear local user preferences and navigate away.
        // If client-side user deletion is required, a custom Supabase Edge Function or a different approach would be needed.
        // await supabase_flutter.Supabase.instance.client.auth.currentUser?.delete(); // This method does not exist client-side

        // Clear local user preferences
        await UserPrefs.clearUser();

        Get.snackbar(
          'সফল',
          'অ্যাকাউন্ট সফলভাবে ডিলিট হয়েছে।',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
        Get.offAllNamed('/register'); // Navigate to registration screen
      } on supabase_flutter.AuthException catch (e) {
        String errorMessage = 'অ্যাকাউন্ট ডিলিট ব্যর্থ হয়েছে।';
        // Supabase AuthException might have different error codes or messages
        // You might need to adjust this based on actual Supabase error handling
        if (e.message.contains('requires-recent-login')) {
          // Placeholder for similar Supabase error
          errorMessage =
              'নিরাপত্তার জন্য, আপনার অ্যাকাউন্ট ডিলিট করার আগে আপনাকে সম্প্রতি লগইন করতে হবে। অনুগ্রহ করে আবার লগইন করে চেষ্টা করুন।';
        }
        Get.snackbar(
          'ত্রুটি',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          duration: const Duration(seconds: 5),
        );
      } on supabase_flutter.PostgrestException catch (e) {
        Get.snackbar(
          'ত্রুটি',
          e.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          duration: const Duration(seconds: 5),
        );
      } catch (e) {
        Get.snackbar(
          'ত্রুটি',
          'অ্যাকাউন্ট ডিলিট ব্যর্থ হয়েছে: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'প্রোফাইল সম্পাদনা',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade600, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.grey.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Image Section
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade300, Colors.teal.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white,
                          backgroundImage: _profileImageUrl != null &&
                                  _profileImageUrl!.isNotEmpty
                              ? NetworkImage(_profileImageUrl!) as ImageProvider
                              : (_imageFile != null
                                  ? FileImage(_imageFile!)
                                  : const AssetImage(
                                          'assets/image/default_user.png')
                                      as ImageProvider),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade400,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Referral Information Card
              /* StreamBuilder<Map<String, dynamic>>(
                stream: supabase_flutter.Supabase.instance.client
                    .from('referral_settings')
                    .stream(primaryKey: ['id'])
                    .eq('id', 'status')
                    .single(),
              ),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    final data = snapshot.data!;
                    if (data['isEnabled'] == true) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.card_giftcard,
                                  color: Colors.teal.shade400,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'রেফারেল তথ্য',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'রেফারেল কোড:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.teal.shade200),
                                  ),
                                  child: Text(
                                    _referCode,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'রেফারেল ব্যালেন্স:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.teal.shade200),
                                  ),
                                  child: Text(
                                    '৳${_referBalance.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }
                  }
                  return Container();
                },
              ),
              const SizedBox(height: 20),*/

              // Form Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'প্রোফাইল তথ্য',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'আপনার তথ্য আপডেট করুন',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Form Fields
                    _buildTextFormField(
                      controller: _nameCtrl,
                      label: 'নাম',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 15),

                    _buildDropdownField(
                      value: _division,
                      label: 'বিভাগ',
                      icon: Icons.location_city,
                      items: locationData.keys
                          .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (val) => setState(() {
                        _division = val;
                        _district = null;
                        _upazila = null;
                      }),
                    ),
                    const SizedBox(height: 15),

                    if (_division != null)
                      _buildDropdownField(
                        value: _district,
                        label: 'জেলা',
                        icon: Icons.map,
                        items: locationData[_division!]!
                            .keys
                            .map((d) =>
                                DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (val) => setState(() {
                          _district = val;
                          _upazila = null;
                        }),
                      ),
                    const SizedBox(height: 15),

                    if (_district != null)
                      _buildDropdownField(
                        value: _upazila,
                        label: 'উপজেলা',
                        icon: Icons.location_on,
                        items: locationData[_division!]![_district!]!
                            .keys
                            .map((u) =>
                                DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (val) => setState(() {
                          _upazila = val;
                          _union = null;
                        }),
                      ),
                    const SizedBox(height: 15),

                    if (_upazila != null)
                      _buildDropdownField(
                        value: _union,
                        label: 'ইউনিয়ন',
                        icon: Icons.apartment,
                        items:
                            locationData[_division!]![_district!]![_upazila!]!
                                .map((u) =>
                                    DropdownMenuItem(value: u, child: Text(u)))
                                .toList(),
                        onChanged: (val) => setState(() {
                          _union = val;
                        }),
                      ),
                    const SizedBox(height: 15),

                    _buildTextFormField(
                      controller: _villageCtrl,
                      label: 'গ্রাম',
                      icon: Icons.home,
                    ),
                    const SizedBox(height: 15),

                    _buildTextFormField(
                      controller: _wardCtrl,
                      label: 'ওয়ার্ড নং',
                      icon: Icons.pin_drop,
                    ),
                    const SizedBox(height: 15),

                    _buildTextFormField(
                      controller: _houseCtrl,
                      label: 'বাড়ি নং',
                      icon: Icons.house,
                    ),
                    const SizedBox(height: 15),

                    _buildTextFormField(
                      controller: _roadCtrl,
                      label: 'রোড নং',
                      icon: Icons.add_road,
                    ),
                    const SizedBox(height: 25),

                    // Save Button
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade600, Colors.teal.shade400],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'সেভ করুন',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Logout Button
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade600, Colors.red.shade400],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'লগ আউট',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Delete Account Button
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade600, Colors.grey.shade400],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _deleteAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'অ্যাকাউন্ট ডিলিট করুন',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.teal.shade400,
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      ),
      style: TextStyle(
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.teal.shade400,
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      ),
      style: TextStyle(
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade800,
      ),
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      dropdownColor: Colors.white,
      icon: Icon(
        Icons.arrow_drop_down,
        color: Colors.teal.shade400,
      ),
    );
  }
}
