
import 'package:flutter/material.dart';
import '../l10n.dart';

import 'package:palliatave_care_client/services/api_service.dart';
import 'package:palliatave_care_client/models/api_response.dart'; 
import 'package:palliatave_care_client/widgets/info_dialog.dart';
import 'package:palliatave_care_client/pages/registration_page.dart';
import 'package:palliatave_care_client/pages/main_screen.dart';
import 'package:palliatave_care_client/util/http_status.dart'; 
import '../models/login_response.dart'; 

import 'package:provider/provider.dart';
import 'package:palliatave_care_client/services/notification_service.dart';

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
        await _showInfoDialog(context, apiResponse.message, title: tr(context, 'login_success_title'));
        
        Provider.of<NotificationService>(context, listen: false).connect();
        // ApiService now handles saving token and user profile internally after parsing LoginResponse
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ForYouPage()));
      } else {
        await _showInfoDialog(context, apiResponse.message, title: tr(context, 'login_failed_title'), isError: true);
      }
    }
  }

  Future<void> _showInfoDialog(BuildContext context, String message, {String title = 'Information', bool isError = false}) async {
    // The default title here is a fallback; we pass a translated one from _loginUser.
    // If you call this from somewhere else, you can pass a translated title too.
    final dialogTitle = title == 'Information' ? tr(context, 'dialog_info_title') : title;
    return await showDialog(
      context: context,
      builder: (ctx) => InfoDialog(title: dialogTitle, message: message, isError: isError),
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
                  Text(
                    tr(context, 'app_title'),
                    style: TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    tr(context, 'app_tagline'), // <-- Changed
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 40.0),
                  _buildFeatureItem(
                    Icons.lock_outline,
                    tr(context, 'feature_secure_title'), // <-- Changed
                    tr(context, 'feature_secure_desc'), // <-- Changed
                  ),
                  const SizedBox(height: 20.0),
                  _buildFeatureItem(
                    Icons.people_outline,
                    tr(context, 'feature_expert_title'), // <-- Changed
                    tr(context, 'feature_expert_desc'), // <-- Changed
                  ),
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
                  constraints: const BoxConstraints(maxWidth: 500), // Max width for the form
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(context, 'login_welcome'), // <-- Changed
                          style: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          tr(context, 'login_prompt'), // <-- Changed
                          style: TextStyle(fontSize: 16.0, color: Colors.grey),
                        ),
                        const SizedBox(height: 30.0),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: tr(context, 'email_address_label'), // <-- Changed
                            hintText: 'youremail@example.com',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return tr(context, 'email_validator_empty'); // <-- Changed
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return tr(context, 'email_validator_invalid'); // <-- Changed
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20.0),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: tr(context, 'password_label'), // <-- Changed
                            hintText: tr(context, 'password_hint'), // <-- Changed
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return tr(context, 'password_validator_empty'); // <-- Changed
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15.0),
                         Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   children: [
                        //     Row(
                        //       children: [
                        //         Checkbox(
                        //           value: _rememberMe,
                        //           onChanged: (bool? value) {
                        //             setState(() {
                        //               _rememberMe = value ?? false;
                        //             });
                        //           },
                        //           activeColor: Theme.of(context).primaryColor,
                        //         ),
                        //         Text(tr(context, 'remember_me')), // <-- Changed
                        //       ],
                        //     ),
                        //     TextButton(
                        //       onPressed: () {
                        //         // TODO: Implement forgot password functionality
                        //         print('Forgot Password pressed!');
                        //       },
                        //       child: Text(tr(context, 'forgot_password')), // <-- Changed
                        //     ),
                        //   ],
                         ),
                        const SizedBox(height: 30.0),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loginUser,
                            child: Text(tr(context, 'login_title')),
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
                                text: tr(context, 'no_account_prompt'), // <-- Changed
                                style: TextStyle(color: Colors.grey[700], fontSize: 16.0),
                                children: [
                                  TextSpan(
                                    text: tr(context, 'create_account_now'), // <-- Changed
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

  // This helper widget uses translated strings passed as arguments
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
                title, // Now gets the translated title
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                description, // Now gets the translated description
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