import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import 'package:logger/logger.dart';
import 'package:mime/mime.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final ApiService apiService = ApiService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _doctorIdController = TextEditingController();
  String _role = 'Patient';
  bool _agreeToTerms = false;
  bool _isLoading = false;
  File? _profilePhoto;
  final ImagePicker _picker = ImagePicker();
  final Logger logger = Logger();

  // Function to pick an image from gallery or camera
  Future<void> _pickImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Photo Source'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: Text('Gallery'),
          ),
        ],
      ),
    );
    if (source != null) {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (image != null) {
        // Log file details
        final mimeType = lookupMimeType(image.path) ?? 'unknown';
        final fileSize = await File(image.path).length();
        logger.i(
            'Selected file: path=${image.path}, name=${image.name}, mimeType=$mimeType, size=$fileSize bytes');
        // Validate extension and MIME type
        final extension = image.path.toLowerCase();
        final validExtensions = ['.jpg', '.jpeg', '.png'];
        final validMimeTypes = ['image/jpeg', 'image/png'];
        if (!validExtensions.any((ext) => extension.endsWith(ext))) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('File must have a .jpg, .jpeg, or .png extension')),
          );
          return;
        }
        if (!validMimeTypes.contains(mimeType)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'File must be a JPEG or PNG image (detected: $mimeType)')),
          );
          return;
        }
        // Validate file size (5MB limit)
        if (fileSize > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image size must be less than 5MB')),
          );
          return;
        }
        setState(() {
          _profilePhoto = File(image.path);
        });
      }
    }
  }

  // Function to remove the selected photo
  void _removePhoto() {
    setState(() {
      _profilePhoto = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Image.asset(
                'assets/healththehain_logo.png',
                height: 100,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: Text('Patient'),
                    selected: _role == 'Patient',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _role = 'Patient';
                          _doctorIdController.clear();
                        });
                      }
                    },
                  ),
                  SizedBox(width: 10),
                  ChoiceChip(
                    label: Text('Doctor'),
                    selected: _role == 'Doctor',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _role = 'Doctor';
                        });
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Enter Your Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Enter Your Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                  suffixIcon: _emailController.text.isNotEmpty
                      ? Icon(Icons.check, color: Colors.green)
                      : null,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Enter Your Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: _passwordController.text.isNotEmpty
                      ? Icon(Icons.check, color: Colors.green)
                      : null,
                ),
                obscureText: true,
              ),
              if (_role == 'Doctor') ...[
                SizedBox(height: 10),
                TextField(
                  controller: _doctorIdController,
                  decoration: InputDecoration(
                    labelText: 'Enter Doctor ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                    hintText: 'e.g., DOC123',
                    errorText: _doctorIdController.text.isNotEmpty &&
                            !RegExp(r'^[a-zA-Z0-9]+$')
                                .hasMatch(_doctorIdController.text)
                        ? 'Doctor ID must be alphanumeric'
                        : null,
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ],
              SizedBox(height: 20),
              Column(
                children: [
                  _profilePhoto == null
                      ? Text(
                          _role == 'Doctor'
                              ? 'Profile photo required'
                              : 'No photo selected',
                          style: TextStyle(
                            color: _role == 'Doctor' ? Colors.red : Colors.grey,
                          ),
                        )
                      : CircleAvatar(
                          radius: 50,
                          backgroundImage: FileImage(_profilePhoto!),
                        ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _pickImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF45B3CB),
                        ),
                        child: Text(
                          'Upload Photo',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      if (_profilePhoto != null) ...[
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _removePhoto,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                          child: Text(
                            'Remove Photo',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreeToTerms = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      'I agree to the medidoc Terms of Service and Privacy Policy',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'Garaad by ds, starlin on needls Sarles',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _agreeToTerms && !_isLoading
                    ? () async {
                        setState(() => _isLoading = true);
                        // Client-side validation
                        if (_emailController.text.isEmpty ||
                            _nameController.text.isEmpty ||
                            _passwordController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Please fill all required fields')),
                          );
                          setState(() => _isLoading = false);
                          return;
                        }
                        if (_role == 'Doctor') {
                          if (_doctorIdController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Doctor ID is required')),
                            );
                            setState(() => _isLoading = false);
                            return;
                          }
                          if (_profilePhoto == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Profile photo is required for doctors')),
                            );
                            setState(() => _isLoading = false);
                            return;
                          }
                        }
                        try {
                          await apiService.signup(
                            _emailController.text,
                            _passwordController.text,
                            _nameController.text,
                            _role.toLowerCase(),
                            doctorId: _role == 'Doctor'
                                ? _doctorIdController.text
                                : null,
                            profilePhoto: _profilePhoto,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Sign-up successful! Please log in.'),
                            ),
                          );
                        } catch (e) {
                          String errorMessage =
                              e.toString().replaceFirst('Exception: ', '');
                          if (errorMessage
                              .contains('Only JPEG/PNG images are allowed')) {
                            errorMessage = 'Please upload a JPEG or PNG image';
                          } else if (errorMessage
                              .contains('Doctor ID is required')) {
                            errorMessage = 'Please provide a Doctor ID';
                          } else if (errorMessage
                              .contains('Profile photo is required')) {
                            errorMessage = 'Please upload a profile photo';
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMessage)),
                          );
                          logger.e('Signup failed: $errorMessage');
                        } finally {
                          setState(() => _isLoading = false);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF45B3CB),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Sign Up', style: TextStyle(color: Colors.white)),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? '),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Log In',
                      style: TextStyle(color: Color(0xFF45B3CB)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
