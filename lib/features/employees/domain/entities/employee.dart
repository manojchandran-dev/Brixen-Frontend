class Employee {
  final String id;
  final String employeeCode;
  final String firstName;
  final String? lastName;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? email;
  final String? phone;
  final String? address;
  final DateTime? joiningDate;
  final String? department;
  final String? designation;
  final String? managerId;
  final String? managerName;
  final String? employmentType;
  final double? salary;
  final String? panNumber;
  final String? aadhaarNumber;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String status;
  final String? onboardingStatus;
  final DateTime createdAt;

  const Employee({
    required this.id,
    required this.employeeCode,
    required this.firstName,
    this.lastName,
    this.gender,
    this.dateOfBirth,
    this.email,
    this.phone,
    this.address,
    this.joiningDate,
    this.department,
    this.designation,
    this.managerId,
    this.managerName,
    this.employmentType,
    this.salary,
    this.panNumber,
    this.aadhaarNumber,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.status = 'Active',
    this.onboardingStatus,
    required this.createdAt,
  });

  String get fullName => [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');

  Employee copyWith({
    String? id,
    String? employeeCode,
    String? firstName,
    String? lastName,
    String? gender,
    DateTime? dateOfBirth,
    String? email,
    String? phone,
    String? address,
    DateTime? joiningDate,
    String? department,
    String? designation,
    String? managerId,
    String? managerName,
    String? employmentType,
    double? salary,
    String? panNumber,
    String? aadhaarNumber,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? status,
    String? onboardingStatus,
    DateTime? createdAt,
  }) {
    return Employee(
      id: id ?? this.id,
      employeeCode: employeeCode ?? this.employeeCode,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      joiningDate: joiningDate ?? this.joiningDate,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      employmentType: employmentType ?? this.employmentType,
      salary: salary ?? this.salary,
      panNumber: panNumber ?? this.panNumber,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      status: status ?? this.status,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
