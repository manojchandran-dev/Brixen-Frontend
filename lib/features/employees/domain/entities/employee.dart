/// How an employee is paid: an amount ([Employee.salary]) per shift, hour,
/// week or month — or piece rate, with no amount of its own. What attendance
/// records follows the type:
///   Shift — shifts.   Hourly — hours.   Weekly / Monthly — full or half days.
///   Piece Rate — just present: paid after sales in Salary → Piece rate
///   (work type × quantity).
/// Matches the server's rules (employees/salary.js).
abstract final class SalaryType {
  static const shift = 'SHIFT_RATE';
  static const piece = 'PIECE_RATE';
  static const hourly = 'HOURLY';
  static const weekly = 'WEEKLY';
  static const monthly = 'MONTHLY';
  static const all = [shift, piece, hourly, weekly, monthly];

  static String label(String? type) => switch (type) {
    shift => 'Shift',
    piece => 'Piece Rate',
    hourly => 'Hourly',
    weekly => 'Weekly',
    monthly => 'Monthly',
    _ => 'Not set',
  };

  /// Every type but Piece Rate is paid an amount of its own.
  static bool hasAmount(String? type) => all.contains(type) && type != piece;

  /// Weekly and monthly staff record full or half days.
  static bool isDayBased(String? type) => type == weekly || type == monthly;

  /// "per shift" / "per month"… — after an amount.
  static String perLabel(String? type) => switch (type) {
    shift => 'per shift',
    piece => 'per piece',
    hourly => 'per hour',
    weekly => 'per week',
    monthly => 'per month',
    _ => '',
  };

  /// The salary_period the server keeps alongside the type.
  static String? periodOf(String? type) => switch (type) {
    shift => 'PER_SHIFT',
    piece => 'PER_PIECE',
    hourly || weekly || monthly => type,
    _ => null,
  };

  /// An employee saved before the five types: Shift Rate paid hourly,
  /// weekly or monthly is now that type.
  static String? normalize(String? type, String? period) =>
      type == shift && const [hourly, weekly, monthly].contains(period)
      ? period
      : type;
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

  /// Still on the emailed temporary password (hasn't signed in yet).
  final bool loginPending;

  /// When the setup email last went out, or why it failed.
  final DateTime? setupEmailSentAt;
  final String? setupEmailError;
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
    this.loginPending = false,
    this.setupEmailSentAt,
    this.setupEmailError,
    required this.createdAt,
  });

  String get fullName =>
      [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');

  /// "Shift · ₹600 per shift", "Piece Rate · paid after sales", or for
  /// older employees just the amount.
  String get salarySummary {
    String money(double v) =>
        '₹${v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2)}';
    return switch (salaryType) {
      SalaryType.piece => 'Piece Rate · paid after sales',
      final t when SalaryType.hasAmount(t) => [
        SalaryType.label(t),
        if (salary != null) '${money(salary!)} ${SalaryType.perLabel(t)}',
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
      loginPending: loginPending,
      setupEmailSentAt: setupEmailSentAt,
      setupEmailError: setupEmailError,
    );
  }
}
