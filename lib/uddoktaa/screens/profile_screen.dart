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
  final Map<String, dynamic>? registrationData;

  const ProfileScreen({super.key, this.registrationData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDataLoadedFromArgs = false;
  final _nameCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _emailCtrl = TextEditingController(); // ইমেল কন্ট্রোলার যোগ করা হয়েছে
  final _phoneCtrl = TextEditingController(); // ফোন কন্ট্রোলার যোগ করা হয়েছে
  String? _division, _district, _upazila, _union;
  File? _imageFile;
  String? _profileImageUrl;
  String? _userId;
  String _referCode = '';
  double _referBalance = 0.0;
  bool _isLoading = false; // লোডিং স্টেট যোগ করা হয়েছে
  bool _isReferralEnabled =
      false; // রেফারেল সিস্টেম সক্রিয় কিনা তা ট্র্যাক করার জন্য

  final TextEditingController _wardCtrl = TextEditingController();
  final TextEditingController _houseCtrl = TextEditingController();
  final TextEditingController _roadCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userId = supabase_flutter.Supabase.instance.client.auth.currentUser?.id;

    if (widget.registrationData != null) {
      _populateFieldsFromArguments(widget.registrationData!);
      _isDataLoadedFromArgs = true;
    } else if (_userId != null) {
      _loadUserData();
    }
    _checkReferralSystemStatus(); // রেফারেল সিস্টেম স্ট্যাটাস চেক করার জন্য
  }

  // রেফারেল সিস্টেম স্ট্যাটাস চেক করার ফাংশন
  Future<void> _checkReferralSystemStatus() async {
    try {
      final response = await supabase_flutter.Supabase.instance.client
          .from('referral_settings')
          .select('isEnabled')
          .eq('id', 'status')
          .single();

      if (response['isEnabled'] == true) {
        setState(() {
          _isReferralEnabled = true;
        });
      }
    } catch (e) {
      debugPrint('Error checking referral status: $e');
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = await UserPrefs.getUser();
      if (user != null && _userId != null) {
        _nameCtrl.text = user.name;
        _phoneCtrl.text =
            user.phone; // ফোন কন্ট্রোলারে ফোন নম্বর সেট করা হয়েছে

        // সুপাবেস থেকে ব্যবহারকারী ডেটা লোড করা
        final response = await supabase_flutter.Supabase.instance.client
            .from('users')
            .select()
            .eq('id', _userId!) // 'uid' এর পরিবর্তে 'id' ব্যবহার করা হয়েছে
            .single();

        final data = response;
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

        _profileImageUrl = data['imageUrl'];

        // ইমেল সেট করা
        final currentUser =
            supabase_flutter.Supabase.instance.client.auth.currentUser;
        if (currentUser != null && currentUser.email != null) {
          _emailCtrl.text = currentUser.email!;
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      Get.snackbar(
        'ত্রুটি',
        'ব্যবহারকারী ডেটা লোড করতে সমস্যা হয়েছে',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateFieldsFromArguments(Map<String, dynamic> data) {
    setState(() {
      _nameCtrl.text = data['name'] ?? '';
      _emailCtrl.text = data['email'] ?? '';
      _phoneCtrl.text = data['phone'] ?? '';
      _division = data['division'];
      _district = data['district'];
      _upazila = data['upazila'];
      _union = data['union'];
      _villageCtrl.text = data['village'] ?? '';
      _wardCtrl.text = data['ward'] ?? '';
      _houseCtrl.text = data['house'] ?? '';
      _roadCtrl.text = data['road'] ?? '';
      _profileImageUrl = data['imageUrl'];
      _isLoading =
          false; // Assuming data from registration means it's not loading
    });
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

      final String publicUrl = await supabase_flutter
          .Supabase.instance.client.storage
          .from('profile_images')
          .upload(
            fileName,
            imageFile,
            fileOptions: const supabase_flutter.FileOptions(
              cacheControl: '3600',
              upsert: true, // upsert: true করা হয়েছে যাতে আগের ছবি আপডেট হয়
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
    if (_isLoading) return;

    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _isLoading = true;
      });

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
        setState(() => _isLoading = false);
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

      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_isLoading) return;

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

    // ফর্ম ভ্যালিডেশন যোগ করা হয়েছে
    if (_nameCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'ত্রুটি',
        'নাম দিতে হবে',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    if (_phoneCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'ত্রুটি',
        'ফোন নম্বর দিতে হবে',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase_flutter.Supabase.instance.client.from('users').update({
        'name': _nameCtrl.text,
        'phone': _phoneCtrl.text, // ফোন নম্বর আপডেট করা হয়েছে
        'division': _division,
        'district': _district,
        'upazila': _upazila,
        'union': _union,
        'village': _villageCtrl.text,
        'ward': _wardCtrl.text,
        'house': _houseCtrl.text,
        'road': _roadCtrl.text,
        'imageUrl': _profileImageUrl,
      }).eq('id', _userId!); // 'uid' এর পরিবর্তে 'id' ব্যবহার করা হয়েছে

      final updatedUser = MyUser.User(
        id: _userId!,
        name: _nameCtrl.text,
        phone: _phoneCtrl.text, // ফোন নম্বর আপডেট করা হয়েছে
        email: _emailCtrl.text, // ইমেল যোগ করা হয়েছে
        password: '', // Password is not managed here
        division: _division ?? '',
        district: _district ?? '',
        upazila: _upazila ?? '',
        village: _villageCtrl.text,
        imageUrl: _profileImageUrl,
      );
      await UserPrefs.saveUser(updatedUser);

      Get.snackbar(
        'সফল',
        'প্রোফাইল সফলভাবে আপডেট হয়েছে',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      debugPrint('Error saving profile: $e');
      Get.snackbar(
        'ত্রুটি',
        'প্রোফাইল আপডেট করতে সমস্যা হয়েছে: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);

    try {
      await supabase_flutter.Supabase.instance.client.auth.signOut();
      await UserPrefs.clearUser();
      Get.offAllNamed('/register');
    } catch (e) {
      debugPrint('Error logging out: $e');
      Get.snackbar(
        'ত্রুটি',
        'লগ আউট করতে সমস্যা হয়েছে',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    if (_isLoading) return;

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
      setState(() => _isLoading = true);

      try {
        // Delete profile image from Supabase Storage
        if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
          try {
            final fileName = path.basename(_profileImageUrl!);
            await supabase_flutter.Supabase.instance.client.storage
                .from('profile_images')
                .remove([fileName]);
          } catch (e) {
            debugPrint('Error deleting profile image: $e');
            // ছবি ডিলিট করতে ব্যর্থ হলেও অ্যাকাউন্ট ডিলিট চালিয়ে যাবে
          }
        }

        // Delete user document from Supabase
        await supabase_flutter.Supabase.instance.client
            .from('users')
            .delete()
            .eq('id', _userId!); // 'uid' এর পরিবর্তে 'id' ব্যবহার করা হয়েছে

        // সুপাবেস অ্যাডমিন API ব্যবহার করে অ্যাকাউন্ট ডিলিট করা
        // ক্লায়েন্ট সাইডে সরাসরি ডিলিট করা সম্ভব নয়, তাই আমরা শুধু লোকাল ডেটা ক্লিয়ার করব
        await UserPrefs.clearUser();

        Get.snackbar(
          'সফল',
          'অ্যাকাউন্ট সফলভাবে ডিলিট হয়েছে।',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
        Get.offAllNamed('/register');
      } on supabase_flutter.AuthException catch (e) {
        String errorMessage = 'অ্যাকাউন্ট ডিলিট ব্যর্থ হয়েছে।';

        if (e.message.contains('requires-recent-login')) {
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
        debugPrint('Error deleting account: $e');
        Get.snackbar(
          'ত্রুটি',
          'অ্যাকাউন্ট ডিলিট ব্যর্থ হয়েছে: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          duration: const Duration(seconds: 5),
        );
      } finally {
        setState(() => _isLoading = false);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
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
                              colors: [
                                Colors.teal.shade300,
                                Colors.teal.shade100
                              ],
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
                                    ? NetworkImage(_profileImageUrl!)
                                        as ImageProvider
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
                    if (_isReferralEnabled) // শুধুমাত্র রেফারেল সিস্টেম সক্রিয় থাকলে দেখানো হবে
                      Container(
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
                      ),
                    const SizedBox(height: 20),

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

                          // ইমেল ফিল্ড যোগ করা হয়েছে (শুধু পঠনযোগ্য)
                          _buildReadOnlyTextFormField(
                            controller: _emailCtrl,
                            label: 'ইমেইল',
                            icon: Icons.email,
                          ),
                          const SizedBox(height: 15),

                          // ফোন নম্বর ফিল্ড যোগ করা হয়েছে
                          _buildTextFormField(
                            controller: _phoneCtrl,
                            label: 'ফোন নম্বর',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 15),

                          _buildDropdownField(
                            value: _division,
                            label: 'বিভাগ',
                            icon: Icons.location_city,
                            items: locationData.keys
                                .map((d) =>
                                    DropdownMenuItem(value: d, child: Text(d)))
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
                                  .map((d) => DropdownMenuItem(
                                      value: d, child: Text(d)))
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
                                  .map((u) => DropdownMenuItem(
                                      value: u, child: Text(u)))
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
                              items: locationData[_division!]![_district!]![
                                      _upazila!]!
                                  .map((u) => DropdownMenuItem(
                                      value: u, child: Text(u)))
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
                                colors: [
                                  Colors.teal.shade600,
                                  Colors.teal.shade400
                                ],
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
                              onPressed: _isLoading ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
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
                        onPressed: _isLoading ? null : _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
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
                        onPressed: _isLoading ? null : _deleteAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
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
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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

  // শুধু পঠনযোগ্য টেক্সট ফিল্ড তৈরির জন্য নতুন মেথড
  Widget _buildReadOnlyTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      enabled: false, // ফিল্ডটি ডিসেবল করা হয়েছে
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade500, // লেবেলের রং পরিবর্তন করা হয়েছে
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.grey.shade400, // আইকনের রং পরিবর্তন করা হয়েছে
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        filled: true,
        fillColor: Colors.grey.shade100, // ব্যাকগ্রাউন্ড রং পরিবর্তন করা হয়েছে
      ),
      style: TextStyle(
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade600, // টেক্সটের রং পরিবর্তন করা হয়েছে
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
      value: value,
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
