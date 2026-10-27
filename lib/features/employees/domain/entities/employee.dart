/// How an employee is paid. Shift Rate: [Employee.salary] per month, week,
/// day or hour; attendance records shifts. Piece Rate: always per piece,
/// paid by each work type's rate (no amount of its own); attendance records
/// pieces. Matches the server's rules (employees/salary.js).
abstract final class SalaryType {
  static const shift = 'SHIFT_RATE';
  static const piece = 'PIECE_RATE';
  static const all = [shift, piece];

  static String label(String? type) => switch (type) {
    shift => 'Shift Rate',
    piece => 'Piece Rate',
    _ => 'Not set',
  };

  /// The periods a [type] can be paid by.
  static List<String> periodsFor(String? type) => switch (type) {
    shift => const ['MONTHLY', 'WEEKLY', 'DAILY', 'HOURLY'],
    piece => const ['PER_PIECE'],
    _ => const [],
  };

  static String periodLabel(String? period) => switch (period) {
    'MONTHLY' => 'Monthly',
    'WEEKLY' => 'Weekly',
    'DAILY' => 'Daily',
    'HOURLY' => 'Hourly',
    'PER_PIECE' => 'Per Piece',
    _ => '—',
  };

  /// "per month" / "per day"… — after an amount.
  static String perLabel(String? period) => switch (period) {
    'MONTHLY' => 'per month',
    'WEEKLY' => 'per week',
    'DAILY' => 'per day',
    'HOURLY' => 'per hour',
    'PER_PIECE' => 'per piece',
    _ => '',
  };
}

class Employee {
  final String id;
  final String? companyId;
  final String employeeCode;
  final String firstName;
  final String? lastName;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? email;
  final String? phone;
  final String? address;
  final DateTime? joiningDate;

  /// Display name: the Department master's, or older free text.
  final String? department;
  final String? departmentId;
  final String? designation;
  final String? managerId;
  final String? managerName;
  final String? employmentType;

  /// [SalaryType.shift] or [SalaryType.piece]; null on older employees.
  final String? salaryType;
  final String? salaryPeriod;
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

  /// The employee's own login, if one was ever set up.
  final String? loginEmail;
  final bool loginActive;
  final DateTime createdAt;

  const Employee({
    required this.id,
    this.companyId,
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
    this.departmentId,
    this.designation,
    this.managerId,
    this.managerName,
    this.employmentType,
    this.salaryType,
    this.salaryPeriod,
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
    this.loginEmail,
    this.loginActive = false,
    required this.createdAt,
  });

  String get fullName =>
      [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');

  /// "Shift Rate · ₹600 per day", "Piece Rate · per piece (work type
  /// rates)", or for older employees just the amount.
  String get salarySummary {
    String money(double v) =>
        '₹${v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2)}';
    return switch (salaryType) {
      SalaryType.piece => 'Piece Rate · per piece (work type rates)',
      SalaryType.shift => [
        'Shift Rate',
        if (salary != null)
          '${money(salary!)} ${SalaryType.perLabel(salaryPeriod)}',
      ].join(' · '),
      _ => salary == null ? '—' : money(salary!),
    };
  }

  Employee copyWith({
    String? id,
    String? companyId,
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
    String? departmentId,
    String? designation,
    String? managerId,
    String? managerName,
    String? employmentType,
    String? salaryType,
    String? salaryPeriod,
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
    String? loginEmail,
    bool? loginActive,
  }) {
    return Employee(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
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
      departmentId: departmentId ?? this.departmentId,
      designation: designation ?? this.designation,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      employmentType: employmentType ?? this.employmentType,
      salaryType: salaryType ?? this.salaryType,
      salaryPeriod: salaryPeriod ?? this.salaryPeriod,
      salary: salary ?? this.salary,
      panNumber: panNumber ?? this.panNumber,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      status: status ?? this.status,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      createdAt: createdAt ?? this.createdAt,
      loginEmail: loginEmail ?? this.loginEmail,
      loginActive: loginActive ?? this.loginActive,
    );
  }
}
