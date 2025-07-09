// lib/screens/profile/edit_profile_screen.dart
import 'dart:convert'; // For base64 encoding
import 'dart:io'; // For File operations

import 'package:absensi_project/constants/app_colors.dart';
import 'package:absensi_project/models/app_model.dart';
import 'package:absensi_project/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import for image picking

import '../../widgets/custom_input_field.dart'; // Your CustomInputField
import '../../widgets/primary_button.dart'; // Your PrimaryButton

class EditProfileScreen extends StatefulWidget {
  final User currentUser; // Changed type to User

  const EditProfileScreen({super.key, required this.currentUser});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ApiService _apiService = ApiService(); // Use ApiService
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  File? _pickedImage; // State for newly picked profile photo file
  String? _profilePhotoBase64; // Base64 for the newly picked photo to upload
  String? _initialProfilePhotoUrl; // To store the original URL from currentUser

  bool _isLoading = false; // Add loading state

  @override
  void initState() {
    super.initState();
    // Initialize controller with current user's name
    _nameController = TextEditingController(
      text: widget.currentUser.name, // Use .name property
    );

    // Store the initial profile photo URL from the current user
    _initialProfilePhotoUrl = widget.currentUser.profile_photo;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
      // Convert image to base64 for upload
      List<int> imageBytes = await _pickedImage!.readAsBytes();
      _profilePhotoBase64 = base64Encode(imageBytes);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true; // Set loading to true
      });

      final String newName = _nameController.text.trim();
      bool profileDetailsChanged = false;
      bool profilePhotoChanged = false;

      // 1. Check if name or gender has changed and update
      final bool nameChanged = newName != widget.currentUser.name;

      if (nameChanged) {
        try {
          final ApiResponse<User> response = await _apiService.updateProfile(
            name: newName,
          );

          if (response.statusCode == 200 && response.data != null) {
            profileDetailsChanged = true;
          } else {
            String errorMessage = response.message;
            if (response.errors != null) {
              response.errors!.forEach((key, value) {
                errorMessage += '\n$key: ${(value as List).join(', ')}';
              });
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to update profile details: $errorMessage',
                  ),
                ),
              );
            }
            setState(() {
              _isLoading = false;
            });
            return; // Stop if detail update fails
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('An error occurred updating details: $e')),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // 2. Check if a new profile photo has been selected and upload
      if (_pickedImage != null && _profilePhotoBase64 != null) {
        try {
          final ApiResponse<User> photoResponse = await _apiService
              .updateProfilePhoto(profilePhoto: _profilePhotoBase64!);

          if (photoResponse.statusCode == 200 && photoResponse.data != null) {
            profilePhotoChanged = true;
            // IMPORTANT: Update the initialProfilePhotoUrl with the new URL from the API response
            if (photoResponse.data!.profile_photo != null) {
              _initialProfilePhotoUrl = photoResponse.data!.profile_photo;
            }
            // Clear picked image and base64 as it's now saved and reflected by URL
            _pickedImage = null;
            _profilePhotoBase64 = null;
          } else {
            String errorMessage = photoResponse.message;
            if (photoResponse.errors != null) {
              photoResponse.errors!.forEach((key, value) {
                errorMessage += '\n$key: ${(value as List).join(', ')}';
              });
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to update profile photo: $errorMessage',
                  ),
                ),
              );
            }
            setState(() {
              _isLoading = false;
            });
            return; // Stop if photo update fails
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('An error occurred updating photo: $e')),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (!mounted) return;

      if (profileDetailsChanged || profilePhotoChanged) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        Navigator.pop(context, true); // Pop with true to signal refresh
      } else {
        // If no changes were made to either name/gender or photo
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No changes to save.")));
      }

      setState(() {
        _isLoading = false; // Set loading to false
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Construct full URL for existing profile photo
    ImageProvider<Object>? currentImageProvider;
    if (_pickedImage != null) {
      // If a new image is picked, use it
      currentImageProvider = FileImage(_pickedImage!);
    } else if (_initialProfilePhotoUrl != null &&
        _initialProfilePhotoUrl!.isNotEmpty) {
      // If no new image, but there's an initial URL, use NetworkImage
      // Check if the URL is already a full URL or a relative path
      final String fullImageUrl = _initialProfilePhotoUrl!.startsWith('http')
          ? _initialProfilePhotoUrl!
          : 'https://appabsensi.mobileprojp.com/public/' +
                _initialProfilePhotoUrl!; // Adjust base path as needed
      currentImageProvider = NetworkImage(fullImageUrl);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        backgroundImage:
                            currentImageProvider, // Use the determined image provider
                        child: currentImageProvider == null
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: AppColors.textLight,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _pickImage,
                      child: Text(
                        _pickedImage != null ||
                                (_initialProfilePhotoUrl != null &&
                                    _initialProfilePhotoUrl!.isNotEmpty)
                            ? 'Change Photo'
                            : 'Upload Photo',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 24,
              ), // Space between image section and first input
              // Username (editable) using CustomInputField
              CustomInputField(
                controller: _nameController,
                hintText: 'Name',
                labelText: 'Name',
                icon: Icons.person,
                customValidator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Save Button using PrimaryButton
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : PrimaryButton(
                      label: 'Save Profile',
                      onPressed: _saveProfile,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}