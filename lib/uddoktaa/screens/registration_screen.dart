import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;

import '../data/location_data.dart';
import '../services/user_prefs.dart';
import '../models/user.dart';

class RegistrationScreen extends StatefulWidget {
  final bool fromCart;
  final Future<void> Function(Map<String, dynamic> registrationData)?
      onRegistrationComplete;

  const RegistrationScreen({
    super.key,
    this.fromCart = false,
    this.onRegistrationComplete,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  @override
  void initState() {
    super.initState();
    if (supabase_flutter.Supabase.instance.client.auth.currentUser != null) {
      if (widget.fromCart) {
        Get.back();
      } else {
        Get.offAllNamed('/home');
      }
    }
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _wardController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _roadController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _imageUrl;

  String? _selectedDivision;
  String? _selectedDistrict;
  String? _selectedUpazila;
  String? _selectedUnion;

  String _generateReferCode(String email) {
    String username = email.split('@')[0];
    String prefix = username.length >= 3 ? username.substring(0, 3) : username;
    Random random = Random();
    int randomNumber = random.nextInt(9000) + 1000;
    return '${prefix.toUpperCase()}$randomNumber';
  }

  Future<String?> _uploadImageToSupabaseStorage(
    File imageFile,
    String userEmail,
  ) async {
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

  Future<void> _pickProfileImage() async {
    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedImage != null) {
      setState(() => _isLoading = true);

      try {
        // Just store the image locally, don't upload yet
        final imageFile = File(pickedImage.path);
        if (!await imageFile.exists()) {
          Get.snackbar(
            'ত্রুটি',
            'ছবি ফাইল পাওয়া যায়নি',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
          setState(() => _isLoading = false);
          return;
        }

        // Validate email before storing image
        final userEmail = _emailController.text.trim();
        if (userEmail.isEmpty || !userEmail.contains('@')) {
          Get.snackbar(
            'ত্রুটি',
            'ছবি নির্বাচনের আগে সঠিক ইমেইল ঠিকানা লিখুন।',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
          setState(() => _isLoading = false);
          return;
        }

        // Store the image locally but don't upload yet
        setState(() {
          _profileImage = imageFile;
          _imageUrl = null; // Reset URL since we'll upload after authentication
        });

        Get.snackbar(
          'সফল',
          'ছবি নির্বাচন করা হয়েছে। রেজিস্ট্রেশনের সময় আপলোড করা হবে।',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      } catch (e) {
        debugPrint('Image pick error: $e');
        Get.snackbar(
          'ত্রুটি',
          'ছবি পিক করতে সমস্যা হয়েছে: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      Get.snackbar(
        'ত্রুটি',
        'সঠিক ইমেইল দিন',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }
    try {
      await supabase_flutter.Supabase.instance.client.auth
          .resetPasswordForEmail(email);
      Get.snackbar(
        'ইমেইল পাঠানো হয়েছে',
        'পাসওয়ার্ড রিসেট লিঙ্ক আপনার ইমেইলে পাঠানো হয়েছে',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } on supabase_flutter.AuthException catch (e) {
      Get.snackbar(
        'ত্রুটি',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'ত্রুটি',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      supabase_flutter.AuthResponse response;
      supabase_flutter.User? user;

      try {
        // Create user account first
        response = await supabase_flutter.Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        user = response.user;

        if (user == null) {
          throw const supabase_flutter.AuthException(
              'User registration failed.');
        }

        String referCode = _generateReferCode(email);

        // Upload image AFTER authentication if available
        if (_profileImage != null) {
          _imageUrl = await _uploadImageToSupabaseStorage(
            _profileImage!,
            email,
          );
        }

        final userData = {
          'uid': user.id,
          'name': _nameController.text.trim(),
          'email': email,
          'phone': _phoneController.text.trim(),
          'division': _selectedDivision,
          'district': _selectedDistrict,
          'upazila': _selectedUpazila,
          'union': _selectedUnion,
          'village': _villageController.text.trim(),
          'ward': _wardController.text.trim(),
          'house': _houseController.text.trim(),
          'road': _roadController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
          'refer_code': referCode,
          'refer_balance': 0,
        };

        if (_imageUrl != null) {
          userData['imageUrl'] = _imageUrl; // Changed to imageUrl
        }

        await supabase_flutter.Supabase.instance.client
            .from('users')
            .insert(userData);

        await UserPrefs.saveUser(
          User(
            uid: user.id,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            password: password,
            division: _selectedDivision ?? '',
            district: _selectedDistrict ?? '',
            upazila: _selectedUpazila ?? '',
            village: _villageController.text.trim(),
            imageUrl: _imageUrl,
          ),
        );

        // Supabase sends verification email automatically on signUp
        Get.snackbar(
          'সফল',
          'ভেরিফিকেশন ইমেইল পাঠানো হয়েছে। ইনবক্স চেক করুন।',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      } on supabase_flutter.AuthException catch (e) {
        if (e.message.contains('User already registered')) {
          // Try to sign in existing user
          response = await supabase_flutter.Supabase.instance.client.auth
              .signInWithPassword(
            email: email,
            password: password,
          );
          user = response.user;

          if (user == null) {
            throw const supabase_flutter.AuthException('User sign-in failed.');
          }

          final List<Map<String, dynamic>> existingUsers =
              await supabase_flutter.Supabase.instance.client
                  .from('users')
                  .select()
                  .eq('uid', user.id) // Changed to uid
                  .limit(1);

          Map<String, dynamic>? existingData =
              existingUsers.isNotEmpty ? existingUsers.first : null;

          String referCode = existingData?['refer_code'] ?? '';

          if (referCode.isEmpty) {
            referCode = _generateReferCode(email);
          }

          // Upload image AFTER authentication if available
          if (_profileImage != null) {
            _imageUrl = await _uploadImageToSupabaseStorage(
              _profileImage!,
              email,
            );
          }

          final Map<String, dynamic> updateData = {
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'division': _selectedDivision,
            'district': _selectedDistrict,
            'upazila': _selectedUpazila,
            'union': _selectedUnion,
            'village': _villageController.text.trim(),
            'ward': _wardController.text.trim(),
            'house': _houseController.text.trim(),
          };

          if (referCode.isNotEmpty) {
            updateData['refer_code'] = referCode;
            var balance = existingData?['refer_balance'] ?? 0;
            if (balance is String) {
              balance = num.tryParse(balance) ?? 0;
            }
            updateData['refer_balance'] = balance;
          }

          if (_imageUrl != null) {
            updateData['imageUrl'] = _imageUrl; // Changed to imageUrl
          }

          if (existingUsers.isEmpty) {
            await supabase_flutter.Supabase.instance.client
                .from('users')
                .insert({
              ...updateData,
              'uid': user.id, // Changed to uid
              'email': email,
              'created_at': DateTime.now().toIso8601String(),
              'refer_balance': 0,
            });
          } else {
            await supabase_flutter.Supabase.instance.client
                .from('users')
                .update(updateData)
                .eq('uid', user.id); // Changed to uid
          }

          await UserPrefs.saveUser(
            User(
              uid: user.id,
              name: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
              password: password,
              division: _selectedDivision ?? '',
              district: _selectedDistrict ?? '',
              upazila: _selectedUpazila ?? '',
              village: _villageController.text.trim(),
              imageUrl: _imageUrl,
            ),
          );

          Get.snackbar(
            'আপডেট সফল',
            'আপনার তথ্য আপডেট করা হয়েছে।',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
          );
        } else {
          Get.snackbar(
            'ত্রুটি',
            e.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
          return;
        }
      }

      await UserPrefs.saveUser(
        User(
          uid: user!.id,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          password: password,
          division: _selectedDivision ?? '',
          district: _selectedDistrict ?? '',
          upazila: _selectedUpazila ?? '',
          village: _villageController.text.trim(),
          imageUrl: _imageUrl,
        ),
      );

      final registrationData = {
        'name': _nameController.text.trim(),
        'email': email,
        'phone': _phoneController.text.trim(),
        'division': _selectedDivision,
        'district': _selectedDistrict,
        'upazila': _selectedUpazila,
        'union': _selectedUnion,
        'village': _villageController.text.trim(),
        'ward': _wardController.text.trim(),
        'house': _houseController.text.trim(),
        'road': _roadController.text.trim(),
        'imageUrl': _imageUrl, // Changed to imageUrl
      };

      if (widget.fromCart) {
        if (widget.onRegistrationComplete != null) {
          await widget.onRegistrationComplete!(registrationData);
        } else {
          Get.back();
        }
      } else {
        Get.offAllNamed('/home');
      }
    } on supabase_flutter.PostgrestException catch (e) {
      Get.snackbar(
        'ত্রুটি',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'ত্রুটি',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _villageController.dispose();
    _wardController.dispose();
    _houseController.dispose();
    _roadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'রেজিস্ট্রেশন',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                    onTap: _pickProfileImage,
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          _imageUrl != null && _imageUrl!.isNotEmpty
                              ? NetworkImage(_imageUrl!) as ImageProvider
                              : (_profileImage != null
                                  ? FileImage(_profileImage!)
                                  : const AssetImage(
                                      'assets/image/default_user.png',
                                    ) as ImageProvider),
                    ),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'নতুন অ্যাকাউন্ট তৈরি করুন',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'নিচের তথ্যগুলো সঠিকভাবে পূরণ করুন',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Form Fields
                      _buildTextFormField(
                        controller: _nameController,
                        label: 'নাম',
                        icon: Icons.person,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'নাম লিখুন'
                            : null,
                      ),
                      const SizedBox(height: 15),

                      _buildTextFormField(
                        controller: _emailController,
                        label: 'ইমেইল',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'ইমেইল লিখুন';
                          }
                          if (!value.contains('@')) return 'সঠিক ইমেইল লিখুন';
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      _buildTextFormField(
                        controller: _phoneController,
                        label: 'ফোন নম্বর',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'ফোন নম্বর লিখুন';
                          }
                          if (!RegExp(r'^\d{10,15}$').hasMatch(value)) {
                            return 'সঠিক ফোন নম্বর দিন';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      _buildTextFormField(
                        controller: _passwordController,
                        label: 'পাসওয়ার্ড',
                        icon: Icons.lock,
                        obscureText: !_isPasswordVisible,
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.teal.shade400,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            TextButton(
                              onPressed: _sendPasswordResetEmail,
                              child: Text(
                                'ভুলে গেছেন?',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade400,
                                ),
                              ),
                            ),
                          ],
                        ),
                        validator: (value) =>
                            (value == null || value.length < 6)
                                ? 'কমপক্ষে ৬ অক্ষর পাসওয়ার্ড দিন'
                                : null,
                      ),
                      const SizedBox(height: 15),

                      _buildDropdownField(
                        value: _selectedDivision,
                        label: 'বিভাগ',
                        icon: Icons.location_city,
                        items: locationData.keys
                            .map(
                              (division) => DropdownMenuItem(
                                value: division,
                                child: Text(division),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDivision = value;
                            _selectedDistrict = null;
                            _selectedUpazila = null;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'বিভাগ নির্বাচন করুন' : null,
                      ),
                      const SizedBox(height: 15),

                      if (_selectedDivision != null)
                        _buildDropdownField(
                          value: _selectedDistrict,
                          label: 'জেলা',
                          icon: Icons.map,
                          items: locationData[_selectedDivision]!
                              .keys
                              .map(
                                (district) => DropdownMenuItem(
                                  value: district,
                                  child: Text(district),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDistrict = value;
                              _selectedUpazila = null;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'জেলা নির্বাচন করুন' : null,
                        ),
                      const SizedBox(height: 15),

                      if (_selectedDistrict != null)
                        _buildDropdownField(
                          value: _selectedUpazila,
                          label: 'উপজেলা',
                          icon: Icons.location_on,
                          items: locationData[_selectedDivision]![
                                  _selectedDistrict]!
                              .keys
                              .map(
                                (upazila) => DropdownMenuItem(
                                  value: upazila,
                                  child: Text(upazila),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedUpazila = value;
                              _selectedUnion = null;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'উপজেলা নির্বাচন করুন' : null,
                        ),
                      const SizedBox(height: 15),

                      if (_selectedUpazila != null)
                        _buildDropdownField(
                          value: _selectedUnion,
                          label: 'ইউনিয়ন',
                          icon: Icons.apartment,
                          items: locationData[_selectedDivision]![
                                  _selectedDistrict]![_selectedUpazila]!
                              .map(
                                (union) => DropdownMenuItem(
                                  value: union,
                                  child: Text(union),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedUnion = value;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'ইউনিয়ন নির্বাচন করুন' : null,
                        ),
                      const SizedBox(height: 15),

                      _buildTextFormField(
                        controller: _villageController,
                        label: 'গ্রাম',
                        icon: Icons.home,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'গ্রাম লিখুন'
                            : null,
                      ),
                      const SizedBox(height: 15),

                      _buildTextFormField(
                        controller: _wardController,
                        label: 'ওয়ার্ড নং',
                        icon: Icons.pin_drop,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'ওয়ার্ড নং লিখুন'
                            : null,
                      ),
                      const SizedBox(height: 15),

                      _buildTextFormField(
                        controller: _houseController,
                        label: 'বাড়ি নং',
                        icon: Icons.house,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'বাড়ি নং লিখুন'
                            : null,
                      ),
                      const SizedBox(height: 15),

                      _buildTextFormField(
                        controller: _roadController,
                        label: 'রোড নং',
                        icon: Icons.add_road,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'রোড নং লিখুন'
                            : null,
                      ),
                      const SizedBox(height: 25),

                      // Register Button
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.teal.shade600,
                              Colors.teal.shade400,
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
                          onPressed: _isLoading ? null : _registerUser,
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
                                  'রেজিস্টার করুন',
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
              ),
              const SizedBox(height: 20),

              // Footer
              Text(
                'রেজিস্ট্রেশন করার মাধ্যমে আপনি আমাদের শর্তাবলী মেনে নিচ্ছেন',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
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
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
        prefixIcon: Icon(icon, color: Colors.teal.shade400, size: 20),
        suffixIcon: suffixIcon,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 15,
        ),
      ),
      style: TextStyle(
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade800,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
        prefixIcon: Icon(icon, color: Colors.teal.shade400, size: 20),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 15,
        ),
      ),
      style: TextStyle(
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade800,
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
      dropdownColor: Colors.white,
      icon: Icon(Icons.arrow_drop_down, color: Colors.teal.shade400),
    );
  }
}
