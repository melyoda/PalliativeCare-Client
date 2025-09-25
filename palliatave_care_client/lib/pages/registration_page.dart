
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:palliatave_care_client/l10n.dart';

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
        await _showInfoDialog(context, tr(context, 'passwords_do_not_match'), isError: true);
        return;
      }

      final ApiResponse<LoginResponse> apiResponse = await _apiService.registerUser(
        firstName: _firstNameController.text,
        middleName: _middleNameController.text,
        lastName: _familyNameController.text,
        birthDate: _selectedDate!.toIso8601String(),
        mobile: _mobileNoController.text,
        email: _emailController.text,
        address: _addressController.text,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        role: _selectedUserType.name.toUpperCase(),
      );

      if (apiResponse.status == HttpStatus.CREATED.name) {
        await _showInfoDialog(context, apiResponse.message, title: tr(context, 'registration_success_title'));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
      } else {
        await _showInfoDialog(context, apiResponse.message, title: tr(context, 'registration_failed_title'), isError: true);
      }
    }
  }

  Future<void> _showInfoDialog(BuildContext context, String message, {String title = 'Information', bool isError = false}) async {
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
                    tr(context, 'registration_tagline'), // <-- Changed
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 40.0),
                  _buildFeatureItem(
                      Icons.group_add, tr(context, 'feature_patients_title'), tr(context, 'feature_patients_desc')), // <-- Changed
                  const SizedBox(height: 20.0),
                  _buildFeatureItem(Icons.medical_services, tr(context, 'feature_providers_title'),
                      tr(context, 'feature_providers_desc')), // <-- Changed
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
                        Text(
                          tr(context, 'create_your_account'), // <-- Changed
                          style: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          tr(context, 'registration_prompt'), // <-- Changed
                          style: TextStyle(fontSize: 16.0, color: Colors.grey),
                        ),
                        const SizedBox(height: 30.0),
                        Text(
                          tr(context, 'registering_as'), // <-- Changed
                          style: TextStyle(fontSize: 16.0, color: Colors.black87, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10.0),
                        LayoutBuilder(
                          builder: (BuildContext context, BoxConstraints constraints) {
                            final double buttonWidth = (constraints.maxWidth / 2) - 16.0;

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
                                constraints: BoxConstraints.tightFor(width: buttonWidth, height: 60),
                                children: <Widget>[
                                  UserTypeToggleButtonContent(
                                      icon: Icons.personal_injury, label: tr(context, 'user_type_patient')), // <-- Changed
                                  UserTypeToggleButtonContent(
                                      icon: Icons.medical_information, label: tr(context, 'user_type_provider')), // <-- Changed
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 30.0),
                        Text(
                          tr(context, 'personal_information'), // <-- Changed
                          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 15.0),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _firstNameController,
                                decoration: InputDecoration(
                                    labelText: tr(context, 'first_name_label'), hintText: tr(context, 'first_name_hint')), // <-- Changed
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return tr(context, 'first_name_validator'); // <-- Changed
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 15.0),
                            Expanded(
                              child: TextFormField(
                                controller: _middleNameController,
                                decoration: InputDecoration(
                                    labelText: tr(context, 'middle_name_label'), hintText: tr(context, 'middle_name_hint')), // <-- Changed
                              ),
                            ),
                            const SizedBox(width: 15.0),
                            Expanded(
                              child: TextFormField(
                                controller: _familyNameController,
                                decoration: InputDecoration(
                                    labelText: tr(context, 'family_name_label'), hintText: tr(context, 'family_name_hint')), // <-- Changed
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return tr(context, 'family_name_validator'); // <-- Changed
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
                          decoration: InputDecoration(
                            labelText: tr(context, 'birth_date_label'), // <-- Changed
                            hintText: tr(context, 'birth_date_hint'), // <-- Changed
                            suffixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          onTap: () => _selectDate(context),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return tr(context, 'birth_date_validator'); // <-- Changed
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20.0),
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                              labelText: tr(context, 'address_label'), hintText: tr(context, 'address_hint')), // <-- Changed
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return tr(context, 'address_validator'); // <-- Changed
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30.0),
                        Text(
                          tr(context, 'contact_information'), // <-- Changed
                          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 15.0),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                    labelText: tr(context, 'email_address_label'), hintText: 'your.email@example.com'), // <-- Changed
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
                            ),
                            const SizedBox(width: 15.0),
                            Expanded(
                              child: TextFormField(
                                controller: _mobileNoController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                    labelText: tr(context, 'mobile_number_label'),
                                    hintText: tr(context, 'mobile_number_hint')), // <-- Changed
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return tr(context, 'mobile_number_validator'); // <-- Changed
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30.0),
                        Text(
                          tr(context, 'security_section_title'), // <-- Changed
                          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 15.0),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                    labelText: tr(context, 'create_password_label'),
                                    hintText: tr(context, 'create_password_hint')), // <-- Changed
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return tr(context, 'password_validator_enter'); // <-- Changed
                                  }
                                  if (value.length < 6) {
                                    return tr(context, 'password_validator_length'); // <-- Changed
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
                                decoration: InputDecoration(
                                    labelText: tr(context, 'confirm_password_label'),
                                    hintText: tr(context, 'confirm_password_hint')), // <-- Changed
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return tr(context, 'confirm_password_validator'); // <-- Changed
                                  }
                                  if (value != _passwordController.text) {
                                    return tr(context, 'passwords_validator_match'); // <-- Changed
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
                            child: Text(tr(context, 'create_account_button')), // <-- Changed
                          ),
                        ),
                        const SizedBox(height: 30.0),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                  context, MaterialPageRoute(builder: (context) => const LoginPage()));
                            },
                            child: RichText(
                              text: TextSpan(
                                text: tr(context, 'already_have_account'), // <-- Changed
                                style: TextStyle(color: Colors.grey[700], fontSize: 16.0),
                                children: [
                                  TextSpan(
                                    text: tr(context, 'sign_in_here'), // <-- Changed
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