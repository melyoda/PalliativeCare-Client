
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:palliatave_care_client/services/api_service.dart';
import 'package:palliatave_care_client/models/api_response.dart'; 
import 'package:palliatave_care_client/widgets/info_dialog.dart';
import 'package:palliatave_care_client/pages/login_page.dart';
import 'package:palliatave_care_client/models/user_type.dart'; 
import 'package:palliatave_care_client/widgets/user_type_toggle_button_content.dart';
import 'package:palliatave_care_client/util/http_status.dart'; // Import HttpStatus
import '../models/login_response.dart';


class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _familyNameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileNoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  UserType _selectedUserType = UserType.patient; // Default to patient
  final List<bool> _isSelected = [true, false]; // For ToggleButtons

  DateTime? _selectedDate;

  final ApiService _apiService = ApiService(); // Instantiate the API service

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        await _showInfoDialog(context, "Passwords do not match.", isError: true); // AWAIT here
        return;
      }

      // Prepare data for the API call with correct backend field names
      final ApiResponse<LoginResponse> apiResponse = await _apiService.registerUser(
        firstName: _firstNameController.text,
        middleName: _middleNameController.text,
        lastName: _familyNameController.text, // Mapped to 'lastName'
        birthDate: _selectedDate!.toIso8601String(),
        mobile: _mobileNoController.text, // Mapped to 'mobile'
        email: _emailController.text,
        address: _addressController.text,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text, // Now included
        role: _selectedUserType.name.toUpperCase(), // Mapped to 'role'
      );

      // --- FIX IS HERE ---
      if (apiResponse.status == HttpStatus.CREATED.name) { // Compare with the string name "CREATED"
        await _showInfoDialog(context, apiResponse.message, title: "Registration Successful!"); // AWAIT here
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
      } else {
        await _showInfoDialog(context, apiResponse.message, title: "Registration Failed", isError: true); // AWAIT here
      }
    }
  }

  Future<void> _showInfoDialog(BuildContext context, String message, {String title = 'Information', bool isError = false}) async { // Changed to async and returns Future
    return await showDialog(
      context: context,
      builder: (ctx) => InfoDialog(title: title, message: message, isError: isError),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Pane (Emerald Green Background)
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFF0A6F4E), // Emerald Green
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.favorite_border, color: Colors.white, size: 48.0),
                  const SizedBox(height: 10.0),
                  const Text(
                    'CareConnect',
                    style: TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  const Text(
                    'Join our caring community',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 40.0),
                  _buildFeatureItem(Icons.group_add, 'For Patients', 'Access personalized care and connect with your healthcare team'),
                  const SizedBox(height: 20.0),
                  _buildFeatureItem(Icons.medical_services, 'For Healthcare Providers', 'Deliver compassionate care with advanced tools and insights'),
                  const SizedBox(height: 20.0),
                  _buildFeatureItem(Icons.security, 'HIPAA Compliant', 'Your privacy and security are our top priorities'),
                ],
              ),
            ),
          ),
          // Right Pane (Form)
          Expanded(
            flex: 2,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600), // Max width for the form
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create Your Account',
                          style: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 10.0),
                        const Text(
                          'Join our palliative care community today',
                          style: TextStyle(fontSize: 16.0, color: Colors.grey),
                        ),
                        const SizedBox(height: 30.0),
                        const Text(
                          'I am registering as a:',
                          style: TextStyle(fontSize: 16.0, color: Colors.black87, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10.0),
                        // Using LayoutBuilder to dynamically size ToggleButtons
                        LayoutBuilder(
                          builder: (BuildContext context, BoxConstraints constraints) {
                            final double totalAvailableWidth = constraints.maxWidth;
                            // Calculate button width: half of available width minus some spacing
                            // The 16.0 is an approximate for ToggleButtons internal padding/spacing
                            final double buttonWidth = (totalAvailableWidth / 2) - 16.0; 

                            return Center(
                              child: ToggleButtons(
                                isSelected: _isSelected,
                                onPressed: (int index) {
                                  setState(() {
                                    for (int i = 0; i < _isSelected.length; i++) {
                                      _isSelected[i] = i == index;
                                    }
                                    _selectedUserType = index == 0 ? UserType.patient : UserType.doctor;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8.0),
                                borderColor: Colors.grey[300],
                                selectedBorderColor: Theme.of(context).primaryColor,
                                fillColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                selectedColor: Theme.of(context).primaryColor,
                                color: Colors.grey[600],
                                // Apply calculated constraints for each button
                                constraints: BoxConstraints.tightFor(width: buttonWidth, height: 60),
                                children: const <Widget>[
                                  UserTypeToggleButtonContent(icon: Icons.personal_injury, label: 'Patient'), // Changed from _UserTypeToggleButtonContent
                                  UserTypeToggleButtonContent(icon: Icons.medical_information, label: 'Healthcare Provider'), // Changed from _UserTypeToggleButtonContent
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 30.0),
                        const Text(
                          'Personal Information',
                          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 15.0),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _firstNameController,
                                decoration: const InputDecoration(labelText: 'First Name *', hintText: 'First name'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your first name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 15.0),
                            Expanded(
                              child: TextFormField(
                                controller: _middleNameController,
                                decoration: const InputDecoration(labelText: 'Middle Name', hintText: 'Middle name'),
                              ),
                            ),
                            const SizedBox(width: 15.0),
                            Expanded(
                              child: TextFormField(
                                controller: _familyNameController,
                                decoration: const InputDecoration(labelText: 'Family Name *', hintText: 'Family name'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your family name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20.0),
                        TextFormField(
                          controller: _birthDateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Birth Date *',
                            hintText: 'dd/mm/yyyy',
                            suffixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          onTap: () => _selectDate(context),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select your birth date';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20.0),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(labelText: 'Address *', hintText: 'Enter your full address'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30.0),
                        const Text(
                          'Contact Information',
                          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 15.0),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(labelText: 'Email Address *', hintText: 'your.email@example.com'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 15.0),
                            Expanded(
                              child: TextFormField(
                                controller: _mobileNoController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(labelText: 'Mobile Number *', hintText: 'Your mobile number'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your mobile number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30.0),
                        const Text(
                          'Security',
                          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 15.0),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(labelText: 'Password *', hintText: 'Create a strong password'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters long';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 15.0),
                            Expanded(
                              child: TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                decoration: const InputDecoration(labelText: 'Confirm Password *', hintText: 'Confirm your password'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40.0),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _registerUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF28A745), // A vibrant green
                            ),
                            child: const Text('Create Account'),
                          ),
                        ),
                        const SizedBox(height: 30.0),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                            },
                            child: RichText(
                              text: TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(color: Colors.grey[700], fontSize: 16.0),
                                children: [
                                  TextSpan(
                                    text: 'Sign in here',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 28.0),
        const SizedBox(width: 15.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14.0,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    }
  }
