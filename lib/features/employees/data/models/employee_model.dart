import '../../domain/entities/employee.dart';

class EmployeeModel extends Employee {
  const EmployeeModel({
    required super.id,
    super.companyId,
    required super.employeeCode,
    required super.firstName,
    super.lastName,
    super.gender,
    super.dateOfBirth,
    super.email,
    super.phone,
    super.address,
    super.joiningDate,
    super.department,
    super.designation,
    super.managerId,
    super.managerName,
    super.employmentType,
    super.salary,
    super.panNumber,
    super.aadhaarNumber,
    super.bankName,
    super.accountNumber,
    super.ifscCode,
    super.emergencyContactName,
    super.emergencyContactPhone,
    super.status = 'Active',
    super.onboardingStatus,
    required super.createdAt,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'].toString(),
      companyId: json['company_id']?.toString(),
      employeeCode: (json['employee_code'] ?? json['employeeCode'] ?? '').toString(),
      firstName: (json['first_name'] ?? json['firstName'] ?? '').toString(),
      lastName: json['last_name'] ?? json['lastName'],
      gender: json['gender'],
      dateOfBirth: _parseDate(json['date_of_birth'] ?? json['dateOfBirth']),
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      joiningDate: _parseDate(json['joining_date'] ?? json['joiningDate']),
      department: json['department'],
      designation: json['designation'],
      managerId: (json['manager_id'] ?? json['managerId'])?.toString(),
      managerName: json['manager_name'] ?? json['managerName'],
      employmentType: json['employment_type'] ?? json['employmentType'],
      salary: json['salary'] != null ? double.tryParse(json['salary'].toString()) : null,
      panNumber: json['pan_number'] ?? json['panNumber'],
      aadhaarNumber: json['aadhaar_number'] ?? json['aadhaarNumber'],
      bankName: json['bank_name'] ?? json['bankName'],
      accountNumber: json['account_number'] ?? json['accountNumber'],
      ifscCode: json['ifsc_code'] ?? json['ifscCode'],
      emergencyContactName: json['emergency_contact_name'] ?? json['emergencyContactName'],
      emergencyContactPhone: json['emergency_contact_phone'] ?? json['emergencyContactPhone'],
      status: (json['status'] ?? 'Active').toString(),
      onboardingStatus: json['onboarding_status'] ?? json['onboardingStatus'],
      createdAt: (json['created_at'] ?? json['createdAt']) != null
          ? DateTime.tryParse((json['created_at'] ?? json['createdAt']).toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Step 1 (Personal) — POST /employees. `companyId` is required: the
  /// company this employee belongs to (chosen by a superAdmin, or implicit
  /// for a companyAdmin/employee session — see `Session.companyId`).
  static Map<String, dynamic> toStep1Body(Employee e, {required String companyId}) => {
        'company_id': int.parse(companyId),
        'first_name': e.firstName,
        if (e.lastName != null && e.lastName!.isNotEmpty) 'last_name': e.lastName,
        if (e.gender != null) 'gender': e.gender,
        if (e.dateOfBirth != null) 'date_of_birth': e.dateOfBirth!.toIso8601String(),
        if (e.email != null && e.email!.isNotEmpty) 'email': e.email,
        if (e.phone != null && e.phone!.isNotEmpty) 'phone': e.phone,
        if (e.address != null && e.address!.isNotEmpty) 'address': e.address,
        if (e.emergencyContactName != null && e.emergencyContactName!.isNotEmpty)
          'emergency_contact_name': e.emergencyContactName,
        if (e.emergencyContactPhone != null && e.emergencyContactPhone!.isNotEmpty)
          'emergency_contact_phone': e.emergencyContactPhone,
      };

  /// Step 2 (Employment) — PUT /employees/:id/step2.
  static Map<String, dynamic> toStep2Body(Employee e) => {
        if (e.department != null && e.department!.isNotEmpty) 'department': e.department,
        if (e.designation != null && e.designation!.isNotEmpty) 'designation': e.designation,
        if (e.joiningDate != null) 'joining_date': e.joiningDate!.toIso8601String(),
        if (e.managerId != null) 'manager_id': e.managerId,
        if (e.employmentType != null) 'employment_type': e.employmentType,
        if (e.salary != null) 'salary': e.salary,
        'status': e.status,
      };

  /// Step 3 (Banking) — PUT /employees/:id/step3.
  static Map<String, dynamic> toStep3Body(Employee e) => {
        if (e.bankName != null && e.bankName!.isNotEmpty) 'bank_name': e.bankName,
        if (e.accountNumber != null && e.accountNumber!.isNotEmpty) 'account_number': e.accountNumber,
        if (e.ifscCode != null && e.ifscCode!.isNotEmpty) 'ifsc_code': e.ifscCode,
        if (e.panNumber != null && e.panNumber!.isNotEmpty) 'pan_number': e.panNumber,
        if (e.aadhaarNumber != null && e.aadhaarNumber!.isNotEmpty) 'aadhaar_number': e.aadhaarNumber,
      };

  /// Generic full update (PUT /employees/:id) — used for editing an existing
  /// employee's personal info, since there's no dedicated "step1 update"
  /// endpoint. Server generates `id`/`employee_code`, and `manager_name` is
  /// derived client-side, so neither is sent.
  static Map<String, dynamic> toBody(Employee e) => {
        'first_name': e.firstName,
        if (e.lastName != null && e.lastName!.isNotEmpty) 'last_name': e.lastName,
        if (e.gender != null) 'gender': e.gender,
        if (e.dateOfBirth != null) 'date_of_birth': e.dateOfBirth!.toIso8601String(),
        if (e.email != null && e.email!.isNotEmpty) 'email': e.email,
        if (e.phone != null && e.phone!.isNotEmpty) 'phone': e.phone,
        if (e.address != null && e.address!.isNotEmpty) 'address': e.address,
        if (e.joiningDate != null) 'joining_date': e.joiningDate!.toIso8601String(),
        if (e.department != null && e.department!.isNotEmpty) 'department': e.department,
        if (e.designation != null && e.designation!.isNotEmpty) 'designation': e.designation,
        if (e.managerId != null) 'manager_id': e.managerId,
        if (e.employmentType != null) 'employment_type': e.employmentType,
        if (e.salary != null) 'salary': e.salary,
        if (e.panNumber != null && e.panNumber!.isNotEmpty) 'pan_number': e.panNumber,
        if (e.aadhaarNumber != null && e.aadhaarNumber!.isNotEmpty) 'aadhaar_number': e.aadhaarNumber,
        if (e.bankName != null && e.bankName!.isNotEmpty) 'bank_name': e.bankName,
        if (e.accountNumber != null && e.accountNumber!.isNotEmpty) 'account_number': e.accountNumber,
        if (e.ifscCode != null && e.ifscCode!.isNotEmpty) 'ifsc_code': e.ifscCode,
        if (e.emergencyContactName != null && e.emergencyContactName!.isNotEmpty)
          'emergency_contact_name': e.emergencyContactName,
        if (e.emergencyContactPhone != null && e.emergencyContactPhone!.isNotEmpty)
          'emergency_contact_phone': e.emergencyContactPhone,
        'status': e.status,
      };

  static DateTime? _parseDate(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
}
