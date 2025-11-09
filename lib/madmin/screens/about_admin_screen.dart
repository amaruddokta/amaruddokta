import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:amar_uddokta/uddoktaa/controllers/AboutController.dart';

class AboutAdminScreen extends StatefulWidget {
  const AboutAdminScreen({super.key});

  @override
  State<AboutAdminScreen> createState() => _AboutAdminScreenState();
}

class _AboutAdminScreenState extends State<AboutAdminScreen> {
  final AboutController aboutController = Get.put(AboutController());
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _roleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _pickedImage;
  String? _currentImageUrl;
  bool _deleteImage = false;
  String? _selectedAboutId; // To keep track of the currently edited item

  @override
  void initState() {
    super.initState();
    _loadAboutList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _roleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAboutList() async {
    await aboutController.fetchAboutList();
    if (aboutController.aboutList.isNotEmpty) {
      _selectAboutEntry(aboutController.aboutList.first);
    } else {
      _clearForm();
    }
  }

  void _selectAboutEntry(Map<String, dynamic> entry) {
    setState(() {
      _selectedAboutId = entry['id'];
      _titleController.text = entry['manTitle'] ?? '';
      _subtitleController.text = entry['manSubtitle'] ?? '';
      _roleController.text = entry['manRole'] ?? '';
      _descriptionController.text = entry['manDescription'] ?? '';
      _currentImageUrl = entry['manImageUrl'];
      _pickedImage = null;
      _deleteImage = false;
    });
  }

  void _clearForm() {
    setState(() {
      _selectedAboutId = null;
      _titleController.clear();
      _subtitleController.clear();
      _roleController.clear();
      _descriptionController.clear();
      _currentImageUrl = null;
      _pickedImage = null;
      _deleteImage = false;
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
        _deleteImage = false;
      });
    }
  }

  Future<void> _saveAboutDetails() async {
    if (_formKey.currentState!.validate() && _selectedAboutId != null) {
      String? imageUrlToSave = _currentImageUrl;

      if (_deleteImage) {
        imageUrlToSave = '';
      } else if (_pickedImage != null) {
        imageUrlToSave = await aboutController.uploadImage(_pickedImage!);
      }

      await aboutController.updateAboutData(
        _selectedAboutId!,
        manTitle:
            _titleController.text.isNotEmpty ? _titleController.text : null,
        manSubtitle: _subtitleController.text.isNotEmpty
            ? _subtitleController.text
            : null,
        manRole: _roleController.text.isNotEmpty ? _roleController.text : null,
        manDescription: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        manImageUrl: imageUrlToSave,
        shouldDeleteImage: _deleteImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('About details saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (_selectedAboutId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please select an About entry to edit or add a new one.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteSelectedAboutDetails() async {
    if (_selectedAboutId != null) {
      await aboutController.deleteAboutData(
          _selectedAboutId!, _currentImageUrl);
      _clearForm();
      _loadAboutList(); // Reload list after deletion
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('About entry deleted!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No About entry selected for deletion.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddAboutDialog(BuildContext context) {
    final TextEditingController newTitleController = TextEditingController();
    final TextEditingController newSubtitleController = TextEditingController();
    final TextEditingController newRoleController = TextEditingController();
    final TextEditingController newDescriptionController =
        TextEditingController();
    File? pickedImageForDialog;

    Future<void> pickImageForDialog() async {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        pickedImageForDialog = File(picked.path);
        (context as Element).markNeedsBuild();
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New About Details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image Picker for Dialog
                    GestureDetector(
                      onTap: () async {
                        await pickImageForDialog();
                        setState(() {});
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.deepPurple, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: pickedImageForDialog != null
                              ? Image.file(pickedImageForDialog!,
                                  fit: BoxFit.cover)
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.add_photo_alternate,
                                        size: 30, color: Colors.deepPurple),
                                    Text('Add Image',
                                        style: TextStyle(
                                            color: Colors.deepPurple,
                                            fontSize: 12)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: newTitleController,
                      label: 'Title',
                      icon: Icons.title,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: newSubtitleController,
                      label: 'Subtitle',
                      icon: Icons.subtitles,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a subtitle' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: newRoleController,
                      label: 'Role',
                      icon: Icons.work,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a role' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: newDescriptionController,
                      label: 'Description',
                      icon: Icons.description,
                      maxLines: 3,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a description' : null,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Add'),
                  onPressed: () async {
                    String? newImageUrl;
                    if (pickedImageForDialog != null) {
                      newImageUrl = await aboutController
                          .uploadImage(pickedImageForDialog!);
                    }

                    await aboutController.addAboutData(
                      manTitle: newTitleController.text.isNotEmpty
                          ? newTitleController.text
                          : null,
                      manSubtitle: newSubtitleController.text.isNotEmpty
                          ? newSubtitleController.text
                          : null,
                      manRole: newRoleController.text.isNotEmpty
                          ? newRoleController.text
                          : null,
                      manDescription: newDescriptionController.text.isNotEmpty
                          ? newDescriptionController.text
                          : null,
                      manImageUrl: newImageUrl,
                    );
                    Navigator.of(context).pop();
                    _loadAboutList(); // Reload to show newly added data
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage About Page'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddAboutDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAboutDetails,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _deleteSelectedAboutDetails,
          ),
        ],
      ),
      body: Obx(() {
        if (aboutController.aboutList.isEmpty) {
          return const Center(
            child: Text('No About entries found. Click + to add one.'),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // List of About entries with reordering capability
              Text(
                'Team Members (drag to reorder)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade700,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ReorderableListView(
                  scrollDirection: Axis.horizontal,
                  onReorder: (oldIndex, newIndex) async {
                    await aboutController.reorderItems(oldIndex, newIndex);
                    if (aboutController.aboutList.isNotEmpty) {
                      _selectAboutEntry(aboutController.aboutList[newIndex]);
                    }
                  },
                  children: List.generate(
                    aboutController.aboutList.length,
                    (index) {
                      final entry = aboutController.aboutList[index];
                      final isSelected = _selectedAboutId == entry['id'];
                      return Container(
                        key: ValueKey(entry['id']),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: GestureDetector(
                          onTap: () => _selectAboutEntry(entry),
                          child: Card(
                            color: isSelected
                                ? Colors.deepPurple.shade100
                                : Colors.white,
                            elevation: isSelected ? 8 : 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isSelected
                                  ? const BorderSide(
                                      color: Colors.deepPurple, width: 2)
                                  : BorderSide.none,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.drag_handle,
                                        color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${index + 1}. ${entry['manTitle'] ?? 'Untitled'}',
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? Colors.deepPurple
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_selectedAboutId != null)
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Section
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Profile Image',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.deepPurple, width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: _pickedImage != null
                                        ? Image.file(_pickedImage!,
                                            fit: BoxFit.cover)
                                        : (_currentImageUrl?.isNotEmpty ==
                                                    true &&
                                                !_deleteImage)
                                            ? Image.network(_currentImageUrl!,
                                                fit: BoxFit.cover)
                                            : Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: const [
                                                  Icon(
                                                      Icons.add_photo_alternate,
                                                      size: 50,
                                                      color: Colors.deepPurple),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Tap to add image',
                                                    style: TextStyle(
                                                        color:
                                                            Colors.deepPurple),
                                                  ),
                                                ],
                                              ),
                                  ),
                                ),
                              ),
                              if (_currentImageUrl?.isNotEmpty == true &&
                                  !_deleteImage)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _deleteImage = true;
                                        _pickedImage = null;
                                      });
                                    },
                                    icon: const Icon(Icons.delete),
                                    label: const Text('Remove Current Image'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Form Fields
                      _buildTextField(
                        controller: _titleController,
                        label: 'Title',
                        icon: Icons.title,
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter a title' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _subtitleController,
                        label: 'Subtitle',
                        icon: Icons.subtitles,
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter a subtitle' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _roleController,
                        label: 'Role',
                        icon: Icons.work,
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter a role' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        icon: Icons.description,
                        maxLines: 5,
                        validator: (value) => value!.isEmpty
                            ? 'Please enter a description'
                            : null,
                      ),
                      const SizedBox(height: 32),
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveAboutDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: validator,
      maxLines: maxLines,
    );
  }
}
