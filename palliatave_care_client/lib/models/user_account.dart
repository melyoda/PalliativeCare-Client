class UserAccount {
  final String id;
  final String firstName;
  final String? middleName; // Made nullable as per backend DTO
  final String lastName;
  final String? birthDate; // Made nullable as per backend DTO
  final String? mobile; // Made nullable as per backend DTO
  final String email;
  final String? address; // Made nullable as per backend DTO
  final String role; // "PATIENT" or "DOCTOR" (from backend's Role enum .name())

  UserAccount({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.birthDate,
    this.mobile,
    required this.email,
    this.address,
    required this.role,
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'] as String? ?? 'unknown',
      firstName: json['firstName'] as String? ?? 'Unknown',
      middleName: json['middleName'] as String?,
      lastName: json['lastName'] as String? ?? 'User',
      birthDate: json['birthDate'] as String?,
      mobile: json['mobile'] as String?,
      email: json['email'] as String? ?? 'unknown@example.com',
      address: json['address'] as String?,
      role: json['role']?.toString() ?? 'PATIENT', // Role can be enum or string from backend
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'birthDate': birthDate,
      'mobile': mobile,
      'email': email,
      'address': address,
      'role': role,
    };
  }
}
