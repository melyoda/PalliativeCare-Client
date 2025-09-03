
// Login Page - typically in `lib/pages/login_page.dart`
import 'package:flutter/material.dart';

import 'package:palliatave_care_client/services/api_service.dart';
import 'package:palliatave_care_client/models/api_response.dart'; // Assuming you move ApiResponse there
import 'package:palliatave_care_client/widgets/info_dialog.dart';
import 'package:palliatave_care_client/pages/registration_page.dart';
import 'package:palliatave_care_client/pages/main_screen.dart';
import 'package:palliatave_care_client/util/http_status.dart'; // Import HttpStatus
import '../models/login_response.dart'; 


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;

  final ApiService _apiService = ApiService(); // Instantiate the API service

  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      final ApiResponse<LoginResponse> apiResponse = await _apiService.loginUser(
        _emailController.text,
        _passwordController.text,
      );
      if (apiResponse.status == HttpStatus.OK.name) {
        await _showInfoDialog(context, apiResponse.message, title: "Login Successful!");
        // ApiService now handles saving token and user profile internally after parsing LoginResponse
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ForYouPage()));
      } else {
        await _showInfoDialog(context, apiResponse.message, title: "Login Failed", isError: true);
      }
    }
  }

  Future<void> _showInfoDialog(BuildContext context, String message, {String title = 'Information', bool isError = false}) async {
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
          // Left Pane (Blue Background)
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFF0D47A1), // Dark blue from the design
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
                    'Compassionate care, connected digitally',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 40.0),
                  _buildFeatureItem(Icons.lock_outline, 'Secure & Private', 'Your health data is protected with enterprise-grade security'),
                  const SizedBox(height: 20.0),
                  _buildFeatureItem(Icons.people_outline, 'Expert Care Team', 'Connect with specialized healthcare professionals'),
                ],
              ),
            ),
          ), // <-- Added a comma here!
          // Right Pane (Form)
          Expanded(
            flex: 2,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500), // Max width for the form
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back',
                          style: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 10.0),
                        const Text(
                          'Please sign in to your account to continue',
                          style: TextStyle(fontSize: 16.0, color: Colors.grey),
                        ),
                        const SizedBox(height: 30.0),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email Address', hintText: 'youremail@example.com'),
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
                        const SizedBox(height: 20.0),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Password', hintText: 'Enter your password'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                  activeColor: Theme.of(context).primaryColor,
                                ),
                                const Text('Remember me'),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                // TODO: Implement forgot password functionality
                                print('Forgot Password pressed!');
                              },
                              child: const Text('Forgot password?'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30.0),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loginUser,
                            child: const Text('Sign In'),
                          ),
                        ),
                        const SizedBox(height: 30.0),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RegistrationPage()));
                            },
                            child: RichText(
                              text: TextSpan(
                                text: 'Don\'t have an account? ',
                                style: TextStyle(color: Colors.grey[700], fontSize: 16.0),
                                children: [
                                  TextSpan(
                                    text: 'Create one now',
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
