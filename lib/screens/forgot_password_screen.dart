import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/verify_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEmailValid = false;
  String _selectedMethod = 'email';
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _emailController.addListener(_validateEmail);
  }

  void _validateEmail() {
    final email = _emailController.text;
    final isValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    setState(() {
      _isEmailValid = isValid && email.isNotEmpty;
    });
  }

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedMethod == 'phone') {
        throw Exception('Phone-based OTP is not supported yet.');
      }
      final response = await _apiService.forgotPassword(_emailController.text);
      final otp = response['otp'] ?? '';
      final userId = response['userId'] ?? '';

      if (otp.isEmpty || userId.isEmpty) {
        throw Exception('Invalid response: OTP or userId missing');
      }

      print(
          'Navigating to VerifyOtpScreen with email: ${_emailController.text}, otp: $otp, userId: $userId');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyOtpScreen(
            email: _emailController.text,
            otp: otp,
            userId: userId,
          ),
        ),
      );
    } catch (e) {
      print('Error requesting OTP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to request OTP: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FORGET YOUR PASSWORD?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your email to receive a confirmation code.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.teal,
                labelColor: Colors.teal,
                unselectedLabelColor: Colors.grey,
                onTap: (index) {
                  setState(() {
                    _selectedMethod = index == 0 ? 'email' : 'phone';
                  });
                },
                tabs: const [
                  Tab(text: 'Email'),
                  Tab(text: 'Phone'),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText:
                      _selectedMethod == 'email' ? 'Email' : 'Phone Number',
                  prefixIcon: Icon(
                    _selectedMethod == 'email' ? Icons.email : Icons.phone,
                    color: Colors.grey,
                  ),
                  suffixIcon: _isEmailValid && _selectedMethod == 'email'
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: _selectedMethod == 'email'
                    ? TextInputType.emailAddress
                    : TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return _selectedMethod == 'email'
                        ? 'Please enter your email'
                        : 'Please enter your phone number';
                  }
                  if (_selectedMethod == 'email' &&
                      !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  if (_selectedMethod == 'phone' &&
                      !RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(value)) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Request OTP',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
