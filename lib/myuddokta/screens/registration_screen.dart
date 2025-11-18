import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amar_uddokta/myuddokta/services/auth_service.dart';
import 'package:amar_uddokta/myuddokta/services/user_service.dart';
import 'package:amar_uddokta/myuddokta/models/user.dart' as AppUser;
import '../data/location_data.dart';
import '../services/user_prefs.dart'; // Added a comment to trigger re-analysis

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
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
    serverClientId:
        '537226906943-m3em8ts3is099uchjq25v1qnhj5qbinv.apps.googleusercontent.com', // Replace with your Web application client ID from Google Cloud Console
  );
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    // Check if user is already logged in
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      // If logged in, navigate away
      if (widget.fromCart) {
        Get.back();
      } else {
        Get.offAllNamed('/home');
      }
    }
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
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
  String? _userEmail; // ইমেল সংরক্ষণের জন্য নতুন ভেরিয়েবল

  String? _selectedDivision;
  String? _selectedDistrict;
  String? _selectedUpazila;
  String? _selectedUnion;

  // >>>>> আপডেটেড Google Sign-In মেথড <<<<<
  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      debugPrint("Attempting Google Sign-In...");

      // Step 1: Initiate sign-in flow
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint("User cancelled the sign-in flow.");
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      debugPrint("Google user selected: ${googleUser.email}");

      // Step 2: Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        debugPrint("Failed to get ID token from Google.");
        throw Exception("Google ID token পাওয়া যায়নি।");
      }
      debugPrint("Successfully retrieved ID token.");

      // Step 3: Sign in to Supabase with the ID token using AuthService
      final AppUser.User? appUser = await _authService.signInWithGoogle(
        idToken: googleAuth.idToken!,
        displayName: googleUser.displayName,
        email: googleUser.email,
        phoneNumber: null,
      );

      if (appUser != null) {
        debugPrint("Supabase sign-in successful for user: ${appUser.email}");
        if (mounted) {
          setState(() {
            _userEmail = appUser.email;
            _nameController.text = appUser.name;
          });
        }

        Get.snackbar(
          'সফল',
          'Google সাইন-ইন সফল হয়েছে',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      } else {
        debugPrint("Supabase sign-in failed: User is null.");
        throw Exception("Supabase-এ ব্যবহারকারী সেশন তৈরি করা যায়নি।");
      }
    } on AuthException catch (e) {
      debugPrint("Supabase Auth Error: ${e.message}");
      Get.snackbar(
        'সাইন-ইন ত্রুটি',
        'Supabase সাইন-ইন ব্যর্থ হয়েছে: ${e.message}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 5),
      );
    } on PlatformException catch (e) {
      debugPrint("Platform Error: ${e.code} - ${e.message}");
      Get.snackbar(
        'প্ল্যাটফর্ম ত্রুটি',
        'একটি সিস্টেম-স্তরের ত্রুটি ঘটেছে: ${e.message}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      String errorMessage = "Google সাইন-ইন ব্যর্থ হয়েছে।";

      if (e.toString().contains("network")) {
        errorMessage = "নেটওয়ার্ক ত্রুটি। আপনার ইন্টারনেট সংযোগ পরীক্ষা করুন।";
      } else {
        errorMessage = 'একটি অপ্রত্যাশিত ত্রুটি ঘটেছে: ${e.toString()}';
      }

      Get.snackbar(
        'ত্রুটি',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 5),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
      final String? publicUrl =
          await _userService.uploadProfileImage(imageFile, userEmail);
      return publicUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      Get.snackbar(
          'আপলোড ত্রুটি', 'ছবি আপলোড করার সময় একটি সমস্যা হয়েছে: $e');
      return null;
    }
  }

  Future<void> _pickProfileImage() async {
    if (_userEmail == null || _userEmail!.isEmpty) {
      Get.snackbar('ত্রুটি', 'ছবি নির্বাচনের আগে Google দিয়ে সাইন-ইন করুন।');
      return;
    }

    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() => _isLoading = true);
      try {
        final imageFile = File(pickedImage.path);
        if (await imageFile.exists()) {
          setState(() {
            _profileImage = imageFile;
            _imageUrl = null;
          });
          Get.snackbar('সফল',
              'ছবি নির্বাচন করা হয়েছে। রেজিস্ট্রেশনের সময় আপলোড করা হবে।');
        }
      } catch (e) {
        Get.snackbar('ত্রুটি', 'ছবি পিক করতে সমস্যা হয়েছে: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate() || _userEmail == null) {
      if (_userEmail == null) {
        Get.snackbar('ত্রুটি', 'অনুগ্রহ করে Google দিয়ে সাইন-ইন করুন');
      }
      return;
    }

    setState(() => _isLoading = true);
    final email = _userEmail!;
    final password = _passwordController.text.trim();

    try {
      final user = supabase_flutter.Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception("User not authenticated after Google sign-in.");
      }

      String referCode = _generateReferCode(email);

      // Upload image if selected
      if (_profileImage != null) {
        _imageUrl = await _uploadImageToSupabaseStorage(_profileImage!, email);
      }

      final userData = {
        'id': user.id,
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
        userData['imageUrl'] = _imageUrl;
      }

      // Use upsert to either insert or update in one go
      await supabase_flutter.Supabase.instance.client
          .from('users')
          .upsert(userData)
          .match({'id': user.id});

      await UserPrefs.saveUser(
        AppUser.User(
          id: user.id,
          name: _nameController.text.trim(),
          email: email,
          phone: _phoneController.text.trim(),
          password: password,
          division: _selectedDivision ?? '',
          district: _selectedDistrict ?? '',
          upazila: _selectedUpazila ?? '',
          village: _villageController.text.trim(),
          imageUrl: _imageUrl,
        ),
      );

      Get.snackbar('সফল', 'রেজিস্ট্রেশন সম্পন্ন হয়েছে');

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
        'imageUrl': _imageUrl,
      };

      Get.offAllNamed('/cart');
    } catch (e) {
      Get.snackbar('ত্রুটি', 'রেজিস্ট্রেশন ব্যর্থ: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _villageController.dispose();
    _wardController.dispose();
    _houseController.dispose();
    _roadController.dispose();
    _googleSignIn.disconnect(); // Important for cleanup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('রেজিস্ট্রেশন',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.teal.shade600, Colors.teal.shade400])),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.teal.shade50, Colors.grey.shade100])),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [
                            Colors.teal.shade300,
                            Colors.teal.shade100
                          ]))),
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
                                          'assets/image/default_user.png')
                                      as ImageProvider),
                    ),
                  ),
                  Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: Colors.teal.shade400,
                              shape: BoxShape.circle),
                          child: Icon(Icons.camera_alt,
                              color: Colors.white, size: 20))),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 5))
                    ]),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('নতুন অ্যাকাউন্ট তৈরি করুন',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800)),
                      const SizedBox(height: 5),
                      Text('নিচের তথ্যগুলো সঠিকভাবে পূরণ করুন',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600)),
                      const SizedBox(height: 20),
                      _buildTextFormField(
                          controller: _nameController,
                          label: 'নাম',
                          icon: Icons.person,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'নাম লিখুন'
                              : null),
                      const SizedBox(height: 15),
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300)),
                        child: InkWell(
                          onTap: _isLoading ? null : _signInWithGoogle,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Row(
                              children: [
                                Icon(Icons.email,
                                    color: Colors.teal.shade400, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(
                                        _userEmail ??
                                            'Google দিয়ে সাইন-ইন করুন',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: _userEmail != null
                                                ? Colors.grey.shade800
                                                : Colors.grey.shade600))),
                                if (_userEmail == null)
                                  Icon(Icons.arrow_forward_ios,
                                      color: Colors.teal.shade400, size: 16),
                              ],
                            ),
                          ),
                        ),
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
                          }),
                      const SizedBox(height: 15),
                      _buildTextFormField(
                          controller: _passwordController,
                          label: 'পাসওয়ার্ড',
                          icon: Icons.lock,
                          obscureText: !_isPasswordVisible,
                          suffixIcon: IconButton(
                              icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.teal.shade400),
                              onPressed: () => setState(() =>
                                  _isPasswordVisible = !_isPasswordVisible)),
                          validator: (value) =>
                              (value == null || value.length < 6)
                                  ? 'কমপক্ষে ৬ অক্ষর পাসওয়ার্ড দিন'
                                  : null),
                      const SizedBox(height: 15),
                      _buildDropdownField(
                          value: _selectedDivision,
                          label: 'বিভাগ',
                          icon: Icons.location_city,
                          items: locationData.keys
                              .map((division) => DropdownMenuItem(
                                  value: division, child: Text(division)))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDivision = value;
                              _selectedDistrict = null;
                              _selectedUpazila = null;
                              _selectedUnion = null;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'বিভাগ নির্বাচন করুন' : null),
                      const SizedBox(height: 15),
                      if (_selectedDivision != null)
                        _buildDropdownField(
                            value: _selectedDistrict,
                            label: 'জেলা',
                            icon: Icons.map,
                            items: locationData[_selectedDivision]!
                                .keys
                                .map((district) => DropdownMenuItem(
                                    value: district, child: Text(district)))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedDistrict = value;
                                _selectedUpazila = null;
                                _selectedUnion = null;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'জেলা নির্বাচন করুন' : null),
                      const SizedBox(height: 15),
                      if (_selectedDistrict != null)
                        _buildDropdownField(
                            value: _selectedUpazila,
                            label: 'উপজেলা',
                            icon: Icons.location_on,
                            items: locationData[_selectedDivision]![
                                    _selectedDistrict]!
                                .keys
                                .map((upazila) => DropdownMenuItem(
                                    value: upazila, child: Text(upazila)))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedUpazila = value;
                                _selectedUnion = null;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'উপজেলা নির্বাচন করুন' : null),
                      const SizedBox(height: 15),
                      if (_selectedUpazila != null)
                        _buildDropdownField(
                            value: _selectedUnion,
                            label: 'ইউনিয়ন',
                            icon: Icons.apartment,
                            items: locationData[_selectedDivision]![
                                    _selectedDistrict]![_selectedUpazila]!
                                .map((union) => DropdownMenuItem(
                                    value: union, child: Text(union)))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedUnion = value);
                            },
                            validator: (value) =>
                                value == null ? 'ইউনিয়ন নির্বাচন করুন' : null),
                      const SizedBox(height: 15),
                      _buildTextFormField(
                          controller: _villageController,
                          label: 'গ্রাম',
                          icon: Icons.home,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'গ্রাম লিখুন'
                              : null),
                      const SizedBox(height: 15),
                      _buildTextFormField(
                          controller: _wardController,
                          label: 'ওয়ার্ড নং',
                          icon: Icons.pin_drop,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'ওয়ার্ড নং লিখুন'
                              : null),
                      const SizedBox(height: 15),
                      _buildTextFormField(
                          controller: _houseController,
                          label: 'বাড়ি নং',
                          icon: Icons.house,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'বাড়ি নং লিখুন'
                              : null),
                      const SizedBox(height: 15),
                      _buildTextFormField(
                          controller: _roadController,
                          label: 'রোড নং',
                          icon: Icons.add_road,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'রোড নং লিখুন'
                              : null),
                      const SizedBox(height: 25),
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.teal.shade600,
                              Colors.teal.shade400
                            ]),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.teal.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4))
                            ]),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _registerUser,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25))),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('রেজিস্টার করুন',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                  'রেজিস্ট্রেশন করার মাধ্যমে আপনি আমাদের শর্তাবলী মেনে নিচ্ছেন',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      TextInputType? keyboardType,
      bool obscureText = false,
      Widget? suffixIcon,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade700),
        prefixIcon: Icon(icon, color: Colors.teal.shade400, size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.teal.shade400, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red.shade300)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red.shade400, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      ),
      style:
          TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade800),
      validator: validator,
    );
  }

  Widget _buildDropdownField(
      {required String? value,
      required String label,
      required IconData icon,
      required List<DropdownMenuItem<String>> items,
      required void Function(String?)? onChanged,
      String? Function(String?)? validator}) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade700),
        prefixIcon: Icon(icon, color: Colors.teal.shade400, size: 20),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.teal.shade400, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red.shade300)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red.shade400, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      ),
      style:
          TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade800),
      items: items,
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
      dropdownColor: Colors.white,
      icon: Icon(Icons.arrow_drop_down, color: Colors.teal.shade400),
    );
  }
}
